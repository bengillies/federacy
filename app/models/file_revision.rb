class FileRevision < ActiveRecord::Base
  has_many :revisions, as: :textable
  belongs_to :tiddler, inverse_of: :file_revisions

  before_save :set_defaults

  validates_presence_of :tiddler

  mount_uploader :file, BinaryTiddlerUploader

  def text
    file.url
  end

  def body
    file
  end

  def set_body! attrs
    if attrs["file"].class == String
      # base 64 data uri
      attrs["file"], attrs["content_type"] = file_from_data_uri(attrs["file"])
    end

    self.file = attrs["file"]
    self.content_type = attrs["content_type"]
  end

  def linkable?
    false
  end

  protected

  class DataURIIO < StringIO
    attr_accessor :original_filename, :mime_type

    def self.from_data_uri uri
      if uri.match(%r{^data:([^;]+)?;([^,]+)?,(.*)$})
        mime_type = $1
        encoding = $2
        data = $3
        extension = $1.split('/')[1]

        contents = if encoding == 'base64'
          Base64.decode64(data)
        else
          data
        end

        io = self.new contents
        io.original_filename = "foo.#{extension}"
        io.mime_type = mime_type
        io
      end
    end
  end

  def file_from_data_uri uri
    decoded_file = DataURIIO.from_data_uri uri
    [decoded_file, decoded_file.mime_type]
  end

  def set_defaults
    self.content_type = file.content_type unless file.content_type.blank?
  end
end
