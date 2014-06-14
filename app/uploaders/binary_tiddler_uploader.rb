class BinaryTiddlerUploader < CarrierWave::Uploader::Base
  storage :file

  # Override the directory where uploaded files will be stored.
  def store_dir
    "uploads/tiddlers/#{model.tiddler.space.id}/#{model.tiddler.id}"
  end

  def filename
    extension = "." + file.extension.downcase unless file.extension.downcase.blank?

    @filename_uuid ||= SecureRandom.uuid()
    @filename_uuid + extension
  end
end
