
# Functions for classes that store images as files
module ImagesModule

  # Suffix for medium artist image (ex: artist-medium.jpg)
  MEDIUM_SUFFIX = '-medium'

  # Suffix for small artist image (ex: artist-medium.jpg)
  THUMB_SUFFIX = '-thumb'

  # The images directory path
  # [+absolute+] True if the path must to be absolute. True if it must to be
  # relative to the application root
  # [+returns+] the images directory path, with a trailing '/'
  def self.images_dir(absolute = false)
    path = '/artists_images/'
    if absolute
      path = File.dirname(__FILE__) + '/../../public' + path
    end
    return path
  end

  # The path to the instance image
  # [+size+] The size to get
  # * +:original+ Original size (WARNING: This size is delete after the download)
  # * +:medium+ Medium size
  # * +:thumb+ Small size
  # [+absolute+] True if we must to return the absolute file path. If it's
  # false, it will return the path relative to the application root
  # (/public/artist_images/xxx.xxx)
  # [+extension+] If it's nil, the extension will be searched on the
  # filesystem. If it does no exists, the function will return null. If it's
  # not null, it will return the given extesion for the file, existing or not.
  # [+returns+] The image path. nil if extension is nil and the image does
  # not exist.
  def image_path(size, absolute = false, extension = nil, images_list = nil)
    return ImagesModule.image_path_for_basename(self.name, size, absolute, extension,
      images_list)
  end

  # Deletes the image files of this instance
  def delete_image_files
    [ :original , :medium , :thumb ].each do |size|
      path = image_path(size, true)
      File.delete(path) if path
    end
  end

  # Rename image files
  # [+old_name+] Old name
  def rename_image_files(old_name)
    [ :original , :medium , :thumb ].each do |size|
      old_path = ImagesModule.image_path_for_basename(old_name, size, true)
      if old_path
        extension = File.extname(old_path)
        new_path = image_path(size, true, extension)
        FileUtils.mv(old_path, new_path) if old_path != new_path
      end
    end
  end

  # The path to the image
  # [+artist_name+] Instance name
  # [+size+] The size to get
  # * +:original+ Original size
  # * +:medium+ Medium size
  # * +:thumb+ Small size
  # [+absolute+] True if we must to return the absolute file path. If it's
  # false, it will return the path relative to the application root
  # (/public/artist_images/xxx.xxx)
  # [+extension+] If it's null, the extension will be searched on the
  # filesystem. If it does no exists, the function will return null. If it's
  # not null, it will return the given extesion for the file, existing or not.
  # [+returns+] The image path. nil if extension is nil and the image does
  # not exist.
  def self.image_path_for_basename(artist_name, size, absolute = false, extension = nil,
    images_list = nil)
    # TODO: Handle unknown artist

    return nil if !artist_name

    # File safe name version
    base_name = ImagesModule.image_base_file(artist_name)

    # Append the size suffix
    if size == :medium
      base_name += MEDIUM_SUFFIX
    elsif size == :thumb
      base_name += THUMB_SUFFIX
    end

    if !extension
      # Search the extension on the filesystem
      if images_list
        # Get the file name from the cached images list
        artist_images = images_list[base_name]
        return nil if !artist_images
        #return artist_images[0]
        extension = File.extname(artist_images[0])
      else
        # Search the file on the images directory
        search_path = ImagesModule.images_dir(true) + base_name + '.*'
        files_found = Dir.glob(search_path)
        return nil if files_found.empty?
        extension = File.extname(files_found[0])
      end
    end

    path = ImagesModule.images_dir(absolute) + base_name + extension

    return path
  end

  def self.images_dir_list
    images_list = Dir.entries( ImagesModule.images_dir(true) )
      .group_by { |path| File.basename(path, ".*") }
    return images_list
  end

  # Get a safe file name for a given string
  def self.safe_file_name(name, transliterate = false)
    name = I18n.transliterate(name) if transliterate
    name = name.downcase.gsub(/[^0-9a-z.\-]/, '_')
    return name
  end

  # Get the image base file name, without extension. nil if name is nil
  def self.image_base_file(name)
    return nil if !name
    return ImagesModule.safe_file_name(name)
  end

end
