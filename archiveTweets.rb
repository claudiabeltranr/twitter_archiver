#!/usr/bin/ruby
=begin

This script turns downloadable tweets from twitter into a markdown 
based text file timeline.

To run, change the 'screen_name' and 'TwitterFilename' below.

I THINK that this is all working.  Check the previous gist version 
for a more stable script with far fewer features.  Let me know in the
comments if I'm doing anything terribly wrong here.  This is my pretty
much my first (possibly) usefull script ever.

The format is slightly different from the one used by Brett Terpstra.  
I've included the @{{screen_name}} field so one text file can be used for 
posts, mentions, favorites, and retweets.

The archive folder structure requires the folder structure described in
[Ian Beck](http://beckism.com/2012/07/archiving-tweets/) 

This is based on the work and ideas from:
[Ian Beck](http://beckism.com/2012/07/archiving-tweets/) 2012
[Dr Drang](http://www.leancrew.com/all-this/2012/07/archiving-tweets/) 2012
[Brett Terpstra](https://gist.github.com/3053353) 2012

This was written by [Chris Kinniburgh](http://twitter.com/ckinniburgh)
. . . but was heavily modified by Rainer Sigwald (rainer@sigwald.org)


=end

require 'rubygems'
require 'time'
require 'twitter'

$VERBOSE = nil
$MAX_ATTEMPTS = 10

STDOUT.sync = true

screen_names = []
File.readlines('accounts.txt').each do |line|
  name = line.strip
  unless name.start_with?('#')
    screen_names.push name unless name.empty?
  end
end

Twitter.configure do |config|
  config.consumer_key = 
  config.consumer_secret = 
  config.oauth_token = 
  config.oauth_token_secret = 
end



def newest(screen_name)
  most_recent = 0;

  most_recent = Dir.entries("json/#{screen_name}").map { |filename|
      filename.sub('.json', '').to_i
    }.max
  print "Finding tweets for @#{screen_name} since last downloaded tweet (#{most_recent}).\n"

  num_attempts = 0
  begin
    currentTweets = Twitter.user_timeline(screen_name, :count => 200 , :since_id => most_recent)
  rescue Twitter::Error::TooManyRequests => error
    if num_attempts <= $MAX_ATTEMPTS
      # NOTE: Your process could go to sleep for up to 15 minutes but if you
      # retry any sooner, it will almost certainly fail with the same exception.
      print "Rate limit exceeded, sleeping for #{error.rate_limit.reset_in} to let it reset.\n"
      sleep error.rate_limit.reset_in
      retry
    else
      raise
    end
  end

  if currentTweets.last.id == most_recent
    puts "--"
    fetch_tweets screen_name, currentTweets, "since_id", most_recent
  else
    currentTweets = Twitter.user_timeline(screen_name, :count => 200)
    fetch_tweets screen_name, currentTweets, "since_id", most_recent
  end
end

def full_download(screen_name)
  num_attempts = 0
  begin
    currentTweets = Twitter.user_timeline(screen_name, :count => 200)
  rescue Twitter::Error::TooManyRequests => error
    if num_attempts <= $MAX_ATTEMPTS
      # NOTE: Your process could go to sleep for up to 15 minutes but if you
      # retry any sooner, it will almost certainly fail with the same exception.
      print "Rate limit exceeded, sleeping for #{error.rate_limit.reset_in} to let it reset.\n"
      sleep error.rate_limit.reset_in
      retry
    else
      raise
    end
  end
  
  fetch_tweets screen_name, currentTweets, "max_id", nil
end

def since_id(screen_name, since_id)
  unless since_id.nil?
    currentTweets = Twitter.user_timeline(screen_name, :count => 200 , :since_id => since_id.to_i-1)
    if currentTweets.last.id.to_i == since_id.to_i
      currentTweets = Twitter.user_timeline(screen_name, :count => 200 , :since_id => since_id.to_i)
      fetch_tweets screen_name, currentTweets, "since_id", since_id.to_i
    else
      currentTweets = Twitter.user_timeline(screen_name, :count => 200)
      fetch_tweets screen_name, currentTweets, "since_id", since_id.to_i
    end
  else
    abort("Please specify an integer id. eg: twitterArchiver.rb -s 221080069651693568")
  end
end

def max_id(screen_name, max_id)
  unless max_id.nil?
    currentTweets = Twitter.user_timeline(screen_name, :count => 200 , :max_id => max_id.to_i)
    fetch_tweets screen_name, currentTweets, "max_id", nil
  else
    abort("Please specify an integer id. eg: twitterArchiver.rb -m 221080069651693568")
  end
end


def fetch_tweets(screen_name, passedTweets, type, since_id)
  tweetCount = 0
  breakTweet = 0
  currentTweets = passedTweets
  while tweetCount < 3200
    currentTweets.each do |currentTweet|
      if type == "since_id"
        break breakTweet = currentTweet if currentTweet.id == since_id
      end
      
      jsonfilename = "json/#{screen_name}/#{currentTweet['id']}.json"
      textfilename = "text/#{screen_name}/#{currentTweet['id']}.txt"
      
      f = File.new(jsonfilename, 'w')
      f.print(MultiJson.dump(currentTweet, :pretty=>true))
      f.close

      f = File.new(textfilename, 'w')
      f.print(currentTweet['text'])
      f.close
      
      # Set FS metadata to tweet creation time      
      File.utime(currentTweet['created_at'], currentTweet['created_at'], jsonfilename)
      File.utime(currentTweet['created_at'], currentTweet['created_at'], textfilename)
    end
    if type == "since_id"
      break if breakTweet.id == since_id
    end
    tweetCount = tweetCount + currentTweets.size
    print "Number of Tweets Archived: " + tweetCount.to_s + "\n"

    previousTweets = currentTweets
    num_attempts = 0
    begin
      num_attempts += 1
      currentTweets = Twitter.user_timeline(screen_name, :count => 200, :max_id => currentTweets.last.id-1)
    rescue Twitter::Error::TooManyRequests => error
      if num_attempts <= $MAX_ATTEMPTS
        # NOTE: Your process could go to sleep for up to 15 minutes but if you
        # retry any sooner, it will almost certainly fail with the same exception.
        print "Rate limit exceeded, sleeping for #{error.rate_limit.reset_in} to let it reset.\n"
        sleep error.rate_limit.reset_in
        retry
      else
        raise
      end
    end

    break puts "first=last" if currentTweets.first.id == previousTweets.last.id
    break puts "first=first" if currentTweets.first.id == previousTweets.first.id
    if since_id
      break puts "id=since" if currentTweets.last.id == since_id
    end
  end

  print "Fetching tweets for @#{screen_name} completed.\n"
end


screen_names.each do |screen_name|
  print "Updating archive for @#{screen_name}.\n"
  if !File.directory?("json")
    Dir.mkdir "json"
    Dir.mkdir "text"
  end
  if !File.directory?("json/#{screen_name}")
    Dir.mkdir "json/#{screen_name}"
    Dir.mkdir "text/#{screen_name}"
    full_download screen_name
  else
    newest screen_name
  end
end
