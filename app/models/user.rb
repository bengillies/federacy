class User < ActiveRecord::Base
  has_many :space_users
  has_many :spaces, through: :space_users

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable


  # Define some methods for checking permissions of spaces and tiddlers

  def space_user space
    begin
      space_users.find_by_space_id(space.id)
    rescue ActiveRecord::RecordNotFound
      nil
    end
  end

  def edit_space? space
    perms = space_user space
    perms && (perms.full? || perms.admin?)
  end

  def create_space? tiddler
    true
  end

  def delete_space? space
    perms = space_user space
    perms && perms.admin?
  end

  def edit_tiddler? tiddler
    perms = space_user tiddler.space
    perms && (perms.full? || perms.admin? ||
      (perms.owned_only? && tiddler.creator == self))
  end

  def create_tiddler? space
    perms = space_user space
    perms && (perms.full? || perms.admin? || perms.owned_only?)
  end

  def delete_tiddler? tiddler
    perms = space_user tiddler.space
    perms && (perms.full? || perms.admin? ||
      (perms.owned_only? && tiddler.creator == self))
  end

  def manage_space? space
    perms = space_user space
    perms && perms.admin?
  end

end
