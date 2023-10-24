require 'optparse'
require 'open-uri'
require 'nokogiri'
require 'uri'
require 'net/http'

# Function to fetch a web page
def fetch_web_page(url)
  begin
    Net::HTTP.get_response(URI.parse(url)).body
  rescue StandardError => e
    puts "Error fetching #{url}: #{e.message}"
    return nil
  end
end

# Function to save Web page to a file
def save_web_page(page_content, url, output_dir)
  begin
    filename = File.join(output_dir, File.basename(url) + '.html')
    File.write(filename, page_content)
    return page_content
  rescue StandardError => e
    puts "Error Saving #{url}: #{e.message}"
  end
end

# Function to download and save an asset (e.g., image, stylesheet)
def download_asset(asset_url, output_dir)
  begin
    asset = URI.parse(asset_url)
    response = Net::HTTP.get_response(asset)
    if response.is_a?(Net::HTTPSuccess)
      asset_content = response.body
      path = output_dir + asset.path
      asset_filename = Pathname(path).dirname.mkpath # Making dir path to save the asset
      File.write(path, asset_content)
    end
  rescue StandardError => e
    nil
  end
end

# Function to extract metadata from a web page
def get_metadata(content)
  if content
    doc = Nokogiri::HTML(content)
    {
      'num_links' => doc.css('a').count,
      'images' => doc.css('img').count,
      'last_fetch' => Time.now.strftime('%a %b %d %Y %H:%M:%S UTC')
    }
  else
    nil
  end
end

# Function to download and save assets linked in the web page
def download_assets(page_content, url, output_dir)
  if page_content
    doc = Nokogiri::HTML(page_content)
    assets = []
    puts "\nDownloading Assets for #{url}\n\n"
    doc.css('img, link, script').each do |element|
      asset_url = element['src'] || element['href']
      element['src'] = element['src'].delete_prefix("/") if element['src'] # Updating src url to use dynamic route (Due to permission issues on local machine for absolute path)
      if asset_url
        absolute_url = URI.join(url, asset_url).to_s
        download_asset(absolute_url, output_dir)
      end
    end
    save_web_page(doc.to_html, url, output_dir) # saving the webpage
  end
end

# Parse command-line options
options = {}
OptionParser.new do |opts|
  opts.banner = 'Usage: fetch.rb [options] URL1 [URL2 ...]'

  opts.on('-m', '--metadata', 'Fetch and display metadata') do
    options[:metadata] = true
  end
end.parse!

# Ensure there are URLs to fetch
if ARGV.empty?
  puts 'No URLs provided. Usage: fetch.rb [options] URL1 [URL2 ...]'
  exit 1
end

# Create an output directory if it doesn't exist
output_dir = 'web_pages'
Dir.mkdir(output_dir) unless File.directory?(output_dir)

# Fetch and process each URL
ARGV.each do |url|
  page_content = fetch_web_page(url)
  puts "Web page not found for #{url}" and return unless page_content
  
  download_assets(page_content, url, output_dir) # Download and save linked assets
  if options[:metadata]
    metadata = get_metadata(page_content)
    if metadata
      puts "site: #{url}"
      metadata.each do |key, value|
        puts "#{key}: #{value}"
      end
    end
  end
end