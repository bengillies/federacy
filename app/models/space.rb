class Space < ActiveRecord::Base
  has_many :space_users
  has_many :users, through: :space_users
  has_many :tiddlers, ->{
      select("tiddlers.*, revisions.created_at")
        .includes(:latest_revision)
        .joins(:latest_revision)
        .order("revisions.created_at DESC")
  }, inverse_of: :space, dependent: :destroy

  enum space_type: [:open, :members_only]

  validates_presence_of :name

  before_save :set_defaults

  scope :visible_to_user, ->(user) {
    if user
      joins(:space_users).where(space_users: { user_id: user })
    else
      self.open
    end
  }

  def self.default_scope
    order('updated_at DESC')
  end

  def self.new_with_user user, params
    new_space = Space.new params
    new_space.space_users.build user_id: user.id, access: :admin
    new_space
  end

  def to_s
    name
  end

  private

  def set_defaults
    self.description ||= ''
  end
end
