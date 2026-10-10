class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  attr_accessor :verified_journalist

  def verified_journalist?
    ActiveModel::Type::Boolean.new.cast(@verified_journalist) ||
      email.to_s.end_with?("@journalists.example")
  end
end
