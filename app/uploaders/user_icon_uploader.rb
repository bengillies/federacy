class UserIconUploader < CarrierWave::Uploader::Base
  include CarrierWave::MiniMagick

  storage :file

  # Override the directory where uploaded files will be stored.
  def store_dir
    "uploads/profile_pics/#{model.id}"
  end

  # Provide a default URL as a default if there hasn't been a file uploaded:
  def default_url
    "/images/fallback/default_user.png"
  end

  # Process files as they are uploaded:
  process :resize_to_fill => [256, 256]

  def extension_white_list
    %w(jpg jpeg gif png)
  end

  def filename
    return nil if file.nil?

    extension = 'png'
    extension = file.extension.downcase
    "#{model.name.gsub(' ', '_')}.#{extension}"
  end

end
