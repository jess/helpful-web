require 'activerecord/uuid'

class Person < ActiveRecord::Base
  include ActiveRecord::UUID

  belongs_to :user
  belongs_to :account
  has_many :memberships, through: :user
  has_many :messages
  has_many :read_receipts

  validates :email,
    allow_blank: true,
    format: /\A[^@]+@[^@]+\z/,
    uniqueness: {:scope => :account}

  validates :twitter,
    allow_blank: true,
    uniqueness: {:scope => :account}

  before_save :parse_email

  def member?(account)
    memberships.where(account_id: account.id).exists?
  end

  Membership::ROLES.each do |role_name|
    define_method("account_#{role_name}?") do |account|
      account_member_role?(account, role_name)
    end
  end

  def account_member_role?(account, role)
    memberships.where(account_id: account.id, role: role).exists?
  end

  # Returns the initial(s) for this person (used in avatars)
  def get_initials
    if self.name
      parts = self.name.split(' ')
      return parts.first[0] + parts.last[0]
    else
      return self.email[0]
    end
  end

  private

  # Private: Make sure we only save the address portion of an email address.
  #
  # Returns nothing.
  def parse_email
    mail = Mail::Address.new(self.email.to_ascii)
    self.email = mail.address
  end

end
