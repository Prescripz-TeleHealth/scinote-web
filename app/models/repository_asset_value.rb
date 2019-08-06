# frozen_string_literal: true

class RepositoryAssetValue < ApplicationRecord
  belongs_to :created_by,
             foreign_key: :created_by_id,
             class_name: 'User',
             optional: true
  belongs_to :last_modified_by,
             foreign_key: :last_modified_by_id,
             class_name: 'User',
             optional: true
  belongs_to :asset,
             inverse_of: :repository_asset_value,
             dependent: :destroy
  has_one :repository_cell, as: :value, dependent: :destroy, inverse_of: :value
  accepts_nested_attributes_for :repository_cell

  validates :asset, :repository_cell, presence: true

  SORTABLE_COLUMN_NAME = 'assets.file_file_name'
  SORTABLE_VALUE_INCLUDE = { repository_asset_value: :asset }.freeze

  def formatted
    asset.file_name
  end

  def data
    asset.file_name
  end

  def data_changed?(_new_data)
    true
  end

  def update_data!(new_data, user)
    asset.file.attach(io: StringIO.new(Base64.decode64(new_data[:file_data].split(',')[1])),
                      filename: new_data[:file_name])
    asset.last_modified_by = user
    self.last_modified_by = user
    asset.save! && save!
  end

  def self.new_with_payload(payload, attributes)
    value = new(attributes)
    team = value.repository_cell.repository_column.repository.team
    value.asset = Asset.create!(
      created_by: value.created_by,
      last_modified_by: value.created_by,
      team: team
    )
    value.asset.file.attach(
      io: StringIO.new(Base64.decode64(payload[:file_data].split(',')[1])),
      filename: payload[:file_name]
    )
    value
  end
end
