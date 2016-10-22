twitter_archiver
================

Ruby script to archive all available tweets from multiple users.

Started as a fork of [a gist](https://gist.github.com/3063070) I found through [Dr. Drang](http://www.leancrew.com/all-this/2012/07/archiving-tweets-without-ifttt/#comment-22641).

# Using the script

First download [`archiveTweets.rb`](https://github.com/rainersigwald/twitter_archiver/blob/master/archiveTweets.rb) by clicking on its link, right-clicking on the "Raw" button, and selecting "Download linked file as". Put it in a directory (folder) by itself and open it in a text editor.

## Ruby environment (OS X)

Open Terminal.app and navigate to the directory that you put `archiveTweets.rb` in.

Install the required Ruby libraries by running:

```
gem install --user-install twitter multi_json
```

Ensure that everything has been installed successfully by trying to run the script. It should fail with a message indicating

```
No such file or directory - accounts.txt (Errno::ENOENT)
```

That's ok—we haven't created that file yet.

## API Keys

Access to the Twitter API requires access tokens for both the "Twitter App" and your user. To get them:

1. Click the "Create New App" button at [apps.twitter.com](https://apps.twitter.com).
2. Fill in the required information (since this is for your personal use, name and description don't matter), and create the application.
3. After creating the application, change its "Access level" to "Read only".
4. Go to the "Keys and Access Tokens" tab, copy the "Consumer Key (API Key)", and paste it between the quotes on the [`config.consumer_key`](https://github.com/rainersigwald/twitter_archiver/blob/90d9a6f7dcfb5a1f5430429afbf28c57e358516e/archiveTweets.rb#L40) line.
5. On the same page, copy the "Consumer Secret (API Secret)", and paste it between the quotes on the [`config.consumer_secret`](https://github.com/rainersigwald/twitter_archiver/blob/90d9a6f7dcfb5a1f5430429afbf28c57e358516e/archiveTweets.rb#L41) line.
6. At the bottomof the "Keys and Access Tokens" tab, click "Create my Access Token".
7. Copy your "Access Token" and paste it between the quotes on the [`config.oauth_token`](https://github.com/rainersigwald/twitter_archiver/blob/90d9a6f7dcfb5a1f5430429afbf28c57e358516e/archiveTweets.rb#L42) line.
8. Copy your "Access Token Secret" and paste it between the quotes on the [`config.oauth_token_secret`](https://github.com/rainersigwald/twitter_archiver/blob/90d9a6f7dcfb5a1f5430429afbf28c57e358516e/archiveTweets.rb#L43) line.
9. Save the script.

That should be enough to allow the script to connect to Twitter.

## Specifying accounts to archive

Create a new text file next to `archiveTweets.rb` named `accounts.txt`. Add each account you'd like to collect into that file, one per line, with no `@` symbol. For example,

```
cnnbrk
Reuters
foxnews
# This line doesn't count because it has a '#' in front of it
```

## Running the script

To collect the tweets, run

```
ruby archiveTweets.rb
```

You should see output like this for each account:

```shell-session
$ ruby archiveTweets.rb
Updating archive for @cnnbrk.
Number of Tweets Archived: 200
Number of Tweets Archived: 400
Number of Tweets Archived: 600
Number of Tweets Archived: 800
Number of Tweets Archived: 1000
Number of Tweets Archived: 1200
Number of Tweets Archived: 1400
Number of Tweets Archived: 1600
Number of Tweets Archived: 1800
Number of Tweets Archived: 2000
Number of Tweets Archived: 2200
Number of Tweets Archived: 2400
Number of Tweets Archived: 2600
Number of Tweets Archived: 2800
Number of Tweets Archived: 3000
Number of Tweets Archived: 3200
Fetching tweets for @cnnbrk completed.
```

## Outputs

The script produces folders named `json` and `text` that contain, respectively, JSON versions of each tweet and the pure message text of each tweet.
