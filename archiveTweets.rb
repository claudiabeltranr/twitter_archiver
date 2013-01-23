#!/usr/bin/ruby
=begin

This script turns downloadable tweets from twitter into a markdown 
based text file timeline.

To run, change the 'Username' and 'TwitterFilename' below.

I THINK that this is all working.  Check the previous gist version 
for a more stable script with far fewer features.  Let me know in the
comments if I'm doing anything terribly wrong here.  This is my pretty
much my first (possibly) usefull script ever.

The format is slightly different from the one used by Brett Terpstra.  
I've included the @{{Username}} field so one text file can be used for 
posts, mentions, favorites, and retweets.

This format is:

  @{{Username}} : {{Text}}<br><br>
  [{{CreatedAt}}]({{LinkToTweet}})<br><br>
  --- <br><br>

Note that you can also use Brett Terpstra's markdown formatting and
DrDrang's text formatting usting -T and -D.

DrDrang's formatting:

  @{{Username}} : {{Text}}<br>
  {{CreatedAt}}<br>
  {{LinkToTweet}}<br>
  - - - - - <br>

Brett Terpstra's formatting:
  
  {{Text}}<br><br>
  [{{CreatedAt}}]({{LinkToTweet}})<br><br>
  --- <br><br>

Arguments: use -n -f -s or -m as the LAST argument.

Usage: twitterArchiver.rb [options]
    -T, --Terpstra                   Use Brett Terpstra's markdown formatting.
    -D, --Drang                      Use DrDrang's plain text formatting.
    -f, --full                       Download entire tweet archive (3200 post limit)
    -n, --newest, (-l)               Download all new tweets since the last tweet in archive
    -s id, --since id                Download all new tweets since a specified id
    -m id, --max id                  Download all new tweets after a specified id
    -h, --help                       Show this message

The archive folder structure requires the folder structure described in
[Ian Beck](http://beckism.com/2012/07/archiving-tweets/) 

This is based on the work and ideas from:
[Ian Beck](http://beckism.com/2012/07/archiving-tweets/) 2012
[Dr Drang](http://www.leancrew.com/all-this/2012/07/archiving-tweets/) 2012
[Brett Terpstra](https://gist.github.com/3053353) 2012

This was written by [Chris Kinniburgh](http://twitter.com/ckinniburgh)

TODO
----

* Include favorites and mentions.
* Figure out when the date is changing from UTC to the computer's time.
* Improve the error descriptions
* Improve the Tweets Archived display.
* Figure out "Object#id will be deprecated; use Object#object_id"

=end

require 'rubygems'
require 'twitter'
require 'optparse'

$VERBOSE = nil

STDOUT.sync = true

Username = 'ckinniburgh'
TwitterFilename = '/Users/ckinniburgh/Dropbox/ifttt/twitter/ckinniburgh.md'
Archive = '/Users/ckinniburgh/Dropbox/ifttt/twitter/archive/'

""" Play with this at your own risk  """




def newest
  Dir.chdir(File.expand_path(Archive))
  current_month = Dir["#{Username}-*.md"].last
  # This is extremely convoluted, but not knowing regex meant doing the splits.
  most_recent = 0;

  if $options[:formatting] == "t"
    File.open(current_month).read.split(/---/).each { |recent_tweet|
      if !recent_tweet.nil?
        if most_recent < recent_tweet.split('/status/').last.split(')').first.to_i
          most_recent = recent_tweet.split('/status/').last.split(')').first.to_i
        end
      end
    }
  elsif $options[:formatting] == "d"
    File.open(current_month).read.split(/- - - - -/).each {|recent_tweet|
      if !recent_tweet.nil?
        if most_recent < recent_tweet.split('/status/').last.split(')').first.to_i
          most_recent = recent_tweet.split('/status/').last.split(')').first.to_i
        end
      end
    }
  else
    File.open(current_month).read.split(/---/).each { |recent_tweet|
      if !recent_tweet.nil?
        if !recent_tweet.split('@')[1].nil?
          if recent_tweet.split('@')[1].split(' ').first.downcase == Username.downcase
            most_recent = recent_tweet.split('/status/').last.split(')').first
          end
        end
      end
    }
  end
  print "ACTUAL MOST RECENT: " + most_recent.to_s + "\n"

  if most_recent == 0
    abort("We couldn't find a recent post.")
  end
  print "MOST RECENT" + most_recent.to_s + " \n"
  currentTweets = Twitter.user_timeline(Username, :count => 200 , :since_id => most_recent)
  print "POOP\n"
  if currentTweets.last.id == most_recent
    puts "--"
    fetch_tweets currentTweets, "since_id", most_recent
  else
    currentTweets = Twitter.user_timeline(Username, :count => 200)
    fetch_tweets currentTweets, "since_id", most_recent
  end
end

def full_download
  currentTweets = Twitter.user_timeline(Username, :count => 200)
  fetch_tweets currentTweets, "max_id", nil
end

def since_id(since_id)
  unless since_id.nil?
    currentTweets = Twitter.user_timeline(Username, :count => 200 , :since_id => since_id.to_i-1)
    if currentTweets.last.id.to_i == since_id.to_i
      currentTweets = Twitter.user_timeline(Username, :count => 200 , :since_id => since_id.to_i)
      fetch_tweets currentTweets, "since_id", since_id.to_i
    else
      currentTweets = Twitter.user_timeline(Username, :count => 200)
      fetch_tweets currentTweets, "since_id", since_id.to_i
    end
  else
    abort("Please specify an integer id. eg: twitterArchiver.rb -s 221080069651693568")
  end
end

def max_id(max_id)
  unless max_id.nil?
    currentTweets = Twitter.user_timeline(Username, :count => 200 , :max_id => max_id.to_i)
    fetch_tweets currentTweets, "max_id", nil
  else
    abort("Please specify an integer id. eg: twitterArchiver.rb -m 221080069651693568")
  end
end


def fetch_tweets(passedTweets, type, since_id)

  # Acknowledge twitter api rate limiting
  currentRateLimit = Twitter.rate_limit_status
  print currentRateLimit.remaining_hits.to_s + " Twitter API request(s) remaining this hour\n"
  print "We'll try to keep 10 free.\n"

  tweetCount = 0
  breakTweet = 0
  currentTweets = passedTweets
  while tweetCount < 3200
    currentTweets.each do |currentTweet|
      if type == "since_id"
        break breakTweet = currentTweet if currentTweet.id == since_id
      end
      currentTweetFile = IO.read(TwitterFilename)
      tweetFile = File.open(TwitterFilename, 'w')

      if $options[:formatting] == "t"
        tweetFile.puts currentTweet.full_text + "\n\n"
        tweetFile.puts "[" + currentTweet.created_at.strftime("%B %d, %Y at %I:%M%p") + "](http://www.twitter.com/" + currentTweet.from_user + "/status/" + currentTweet.id.to_s  + ")\n\n"
        tweetFile.puts "--- \n\n"

      elsif $options[:formatting] == "d"
        tweetFile.puts currentTweet.full_text
        tweetFile.puts currentTweet.created_at.strftime("%B %d, %Y at %I:%M%p")
        tweetFile.puts "http://www.twitter.com/" + currentTweet.from_user + "/status/" + currentTweet.id.to_s  + ")"
        tweetFile.puts "- - - - - \n"

      else
        tweetFile.puts "@" + currentTweet.from_user + " : " + currentTweet.full_text + "\n\n"
        tweetFile.puts "[" + currentTweet.created_at.strftime("%B %d, %Y at %I:%M%p") + "](http://www.twitter.com/" + currentTweet.from_user + "/status/" + currentTweet.id.to_s  + ")\n\n"
        tweetFile.puts "--- \n\n"
      end

      tweetFile.puts currentTweetFile
      tweetFile.close
    end
    if type == "since_id"
      break if breakTweet.id == since_id
    end
    tweetCount = tweetCount + currentTweets.size
    print "Number of Tweets Archived: " + tweetCount.to_s + "\n"

    while Twitter.rate_limit_status.remaining_hits < 10
      print "There are less than 10 API calls left accessable this hour.\n"
      timeUntilContinue = Twitter.rate_limit_status.reset_time - Time.now
      print "Waiting until the API resets in " + Time.at(timeUntilContinue).gmtime.strftime('%M minutes and %S seconds') + "\n"
      sleep(timeUntilContinue + 5)
    end

    previousTweets = currentTweets
    currentTweets = Twitter.user_timeline(Username, :count => 200, :max_id => currentTweets.last.id-1)

    break puts "first=last" if currentTweets.first.id == previousTweets.last.id
    break puts "first=first" if currentTweets.first.id == previousTweets.first.id
    if since_id
      break puts "id=since" if currentTweets.last.id == since_id
    end
  end

  print "Ending (hopefully) sucessfully. What a relief."
end

$options = Hash.new
$options[:formatting] = "c"

option_parser = OptionParser.new do |opts|

  opts.banner = "Usage: twitterArchiver.rb [options]"

  opts.on( "-v", "--verbose", "Be verbose") do
    $options[:verbose] = "v"
    puts "Going verbose"
  end

  opts.on( "-T", "--Terpstra", "Use Brett Terpstra's markdown formatting.  NOT FUNCTIONAL") do
    if $options[:formatting] == "d"
      abort("You can't use -D and -T  There can only be one.")
    end
    $options[:formatting] = "t"
  end

  opts.on( "-D", "--Drang", "Use DrDrang's plain text formatting.  NOT FUNCTIONAL") do
    if $options[:formatting] == "t"
      abort("You can't use -D and -T  There can only be one.")
    end
    $options[:formatting] = "d"
  end

  opts.on( "-f", "--full", "Download entire tweet archive (3200 post limit)") do
    full_download
  end

  opts.on( "-n", "-l", "--newest", "Download all new tweets since the last tweet in archive") do
    newest
  end

  opts.on( "-s", "--since id", "Download all new tweets since a specified id") do |since|
    raise OptionParser::MissingArgument if since.nil?
    since_id since
  end

  opts.on( "-m", "--max id", "Download all new tweets after a specified id") do |max|
    max_id max
  end

  opts.on_tail("-h", "--help", "Show this message") do
    puts opts
    exit
  end
end

begin
  option_parser.parse!(ARGV)
rescue OptionParser::ParseError
  $stderr.print "Error: " + $! + "\n"
  exit
end