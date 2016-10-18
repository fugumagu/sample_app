class User < ApplicationRecord
  attr_accessor :remember_token

  before_save { self.email = email.downcase }
  
  has_many :microposts, :dependent => :destroy 
  has_many :active_relationships, :class_name => "Relationship",
                                  :foreign_key => :follower_id,
                                  :dependent => :destroy
  has_many :passive_relationships, :class_name => "Relationship",
                                  :foreign_key => "followed_id",
                                  :dependent => :destroy
  has_many :following, :through => :active_relationships, :source => :followed
  has_many :followers, :through => :passive_relationships, :source => :follower
  
  validates :name, presence: true, length: { maximum: 50 }
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+[a-z]+\.{1}[a-z]+\z/i
  validates :email, presence: true, length: { maximum: 255 },
                    format: { with: VALID_EMAIL_REGEX },
                    uniqueness: { case_sensitive: false }
  has_secure_password
  validates :password, presence: true, length: { minimum: 6 }, allow_nil: true

  has_many :microposts, :dependent => :destroy

  # Returns the hash digest of the given string.
  def self.digest(string)
  	cost = ActiveModel::SecurePassword.min_cost ? BCrypt::Engine::MIN_COST : BCrypt::Engine.cost
  	BCrypt::Password.create(string, cost: cost)
  end

  # Returns a random token.
  def self.new_token
    SecureRandom.urlsave_base64
  end

  def remember 
    self.remember_token = User.new_token
    update_attribute(:remember_digest, User.digest(remember_token))
  end
  
  # Follows a user.
  def follow(other_user)
    active_relationships.create(:followed_id => other_user.id)
  end
  
  def unfollow(other_user)
    active_relationships.find_by(:followed_id => other_user.id).destroy 
  end
  
  def following?(other_user)
    following.include?(other_user)
  end

  # Defines a proto-feed.
  # See "Following users" for the full implementation.
  def feed
    Micropost.where("user_id IN (?) OR user_id = ?", following_ids, id)
  end
end