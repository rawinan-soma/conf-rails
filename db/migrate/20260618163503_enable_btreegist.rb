# frozen_string_literal: true

class EnableBtreegist < ActiveRecord::Migration[8.1]
  def change
    enable_extension "btree_gist"
  end
end
