  # Active record stuff
require 'active_record'
require_relative '../../app/models/constants'
require_relative '../../app/models/artist'
require_relative '../../app/models/album'
require_relative '../../app/models/song'
require_relative '../../app/models/task'
require_relative '../active_record_utils/arutils'
require_relative '../active_record_utils/bulk_operation'
require 'wikipedia'
require 'nokogiri'
require 'open-uri'
require 'uri'
require 'rmagick'
require 'fileutils'

# Search information on wikipedia about the stored songs
class MetaGeneration

  @@running_meta_generation = false

  # Constructor
  # [+settings+] The Setting configuration object
  def initialize(settings)

    @settings = settings
    return if @settings.wikipedia_host.empty?

    # Client configuration
    Wikipedia.Configure {
      domain settings.wikipedia_host
      path   'w/api.php'
    }

  end

  # Update artists database to add links to wikipedia and download images
  def search_artists

    puts "MetaGeneration.search_artists"

    return if @settings.wikipedia_host.empty? || @@running_meta_generation

    Task.do_task('Searching music metadata...') do |task|
      begin
        @@running_meta_generation = true

        puts "Metadata search started"

        # Update pending artists
        Artist.all.where(wikilink: nil).each do |artist|
          update_artist(artist)
        end
      ensure
        @@running_meta_generation = false
      end
    end

  end

  # Set all artists wikipedia links to null
  def self.clean_metadata
    Artist.all.update_all(wikilink: nil)
  end

  # Peforms a text seach on wikipedia
  # [+text+] Text to search
  # [+max_results+] Maximum number of results to get
  # [+returns+] Array of results with names and urls. Format is
  # [ ['name 1','url 1'] , ['name 1','url 2'] ... ]
  def search_text(text, max_results)
    begin

      return [] if @settings.wikipedia_host.empty?

      search = Wikipedia.client.request( {
        action: 'opensearch',
        search: text,
        limit: max_results,
        redirects: 'resolve',
        format: 'json'
      } )

      # search => "[\"GnR\",[\"Guns N' Roses\"],[\"Guns N' Roses is an American hard blah blah.\"],
      #    [\"https://en.wikipedia.org/wiki/Guns_N%27_Roses\"]]"
      search = JSON.parse(search)

      # Format result
      results = []
      names = search[1]
      urls = search[3]
      names.each_with_index do |name, index|
        results << [ name , urls[index] ]
      end
      return results

    rescue
      Log.log_last_exception
      return []
    end
  end

  # Get the url of the main image of a wikipedia article
  # [+wikipedia_url+] The wikipedia articule url
  # [+returns+] nil if the image has not been found
  def get_wikipedia_image_url(wikipedia_url)
    begin

      return nil if !wikipedia_url || wikipedia_url.empty?

      # Download the wikipedia page
      page = Nokogiri::HTML(open(wikipedia_url))

      # Get the image href:
      link = page.css( @settings.image_selector ).first
      return if !link
      image_href = link.attr('href')
      image_href = URI.unescape(image_href)
      # image_href => '/wiki/Archivo:Metallica_at_The_O2_Arena_London_2008.jpg'

      # Get the image "id":
      slash_idx = image_href.rindex('/')
      return if !slash_idx
      image_id = image_href[ slash_idx + 1 .. -1 ]
      # image_id => 'Archivo:Metallica_at_The_O2_Arena_London_2008.jpg'

      # Get the full URL:
      # /w/api.php?action=query&prop=imageinfo&format=json&iiprop=url&titles=Archivo%3AMetallica_at_The_O2_Arena_London_2008.jpg
      image_info = Wikipedia.client.request( {
        action: 'query',
        prop: 'imageinfo',
        iiprop: 'url',
        titles: image_id,
        format: 'json'
      } )
      # result => {
      #     "batchcomplete": "",
      #     "query": {
      #         "normalized": [
      #             {
      #                 "from": "Archivo:Metallica_at_The_O2_Arena_London_2008.jpg",
      #                 "to": "Archivo:Metallica at The O2 Arena London 2008.jpg"
      #             }
      #         ],
      #         "pages": {
      #             "-1": {
      #                 "ns": 6,
      #                 "title": "Archivo:Metallica at The O2 Arena London 2008.jpg",
      #                 "missing": "",
      #                 "imagerepository": "shared",
      #                 "imageinfo": [
      #                     {
      #                         "url": "https://upload.wikimedia.org/wikipedia/commons/0/07/Metallica_at_The_O2_Arena_London_2008.jpg",
      #                         "descriptionurl": "https://commons.wikimedia.org/wiki/File:Metallica_at_The_O2_Arena_London_2008.jpg"
      #                     }
      #                 ]
      #             }
      #         }
      #     }
      # }
      image_info = search = JSON.parse(image_info)

      image_url = image_info['query']['pages']['-1']['imageinfo'][0]['url']
      return image_url
    rescue
      Log.log_last_exception
      return nil
    end
  end

  # Try to download the artist image
  # [+artist+] Artist to get the image
  # [+image_url+] String url of the artist image
  def self.download_artist_image(artist, image_url)

    return if !image_url

    # Get the url file extension:
    uri = URI.parse(image_url)
    file_name = File.basename(uri.path)
    extension = File.extname(file_name)

    # Do not store svg files, are too big
    return if extension.downcase == '.svg'

    # Download the image to /public/artists_images:
    destination_path = ImagesModule.image_path_for_basename(artist.name, :original, true, extension)

    puts "Saving #{image_url} to #{destination_path}"
    File.open(destination_path, "wb") do |saved_file|
      # the following "open" is provided by open-uri
      open( image_url, "rb") do |read_file|
        saved_file.write(read_file.read)
      end
    end

    # Resize the image to medium and thumb
    resize_image( destination_path , ImagesModule::MEDIUM_SUFFIX , 600 )
    resize_image( destination_path , ImagesModule::THUMB_SUFFIX , 100 )

    # Remove the original size: They are usually really big (order of MB)
    File.delete(destination_path)

  end

  ############################################################
  protected
  ############################################################

  # Update meta about an artist
  # [+artist+] Artist to update
  def update_artist(artist)
    begin
      # Handle unknown artist
      if artist.name == Artist::UNKNOWN_ARTIST_NAME
        artist.wikilink = ''
        artist.save
        return
      end

      # Result is like this:
      search = search_text(artist.name, 1)

      if search.length == 0
        artist.wikilink = ''
      else
        artist.wikilink = search[0][1]
      end

      download_wiki_image(artist)
    rescue
      Log.log_last_exception("Error updating #{artist.to_s}")
      artist.wikilink = ''
    end
    artist.save
  end

  # Try to download the artist image from wikipedia
  # [+artist+] Artist to get the image
  def download_wiki_image(artist)

    # Check if the artist image already exists
    return if artist.image_path(:medium)

    image_url = get_wikipedia_image_url(artist.wikilink)
    MetaGeneration::download_artist_image(artist, image_url)
  end

  # Resize an image
  # [+image_path+] Path of the image to resize
  # [+suffix+] Suffix to add to the the resized image name.
  # Ex. 'foo.jpg' -> 'foosuffix.jpg'
  # [+max_size+] Maximu size in pixels for the width / height of the image
  def self.resize_image(image_path, suffix , max_size)

    image = Magick::Image.read(image_path).first
    # x = image.columns
    # y = image.rows

    destination_path = File.dirname(image_path) + '/' +
      File.basename(image_path, '.*') + suffix +
      File.extname(image_path)

    # https://rmagick.github.io/imusage.html#geometry
    geometry = max_size.to_s + 'x' + max_size.to_s + '>'
    image.change_geometry!(geometry) do |cols, rows, img|
      newimg = img.resize(cols, rows)
      newimg.write(destination_path)
    end

  end

end
