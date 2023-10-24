
Run:
ruby fetch.rb [opts]

Example:
ruby fetch.rb https://www.google.com https://autify.com

Run with metadata:
ruby fetch.rb --metadata [opts]

Example:
ruby fetch.rb --metadata https://www.google.com https://autify.com


Run through docker (Might take a bit of time depending on the internet connection/speed):
docker-compose up



Result:
A folder name web_pages should be created in your app directory and it will have the fetched URLs
