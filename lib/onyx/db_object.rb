require_relative 'db_utils'
require 'active_support/inflector'

module Onyx::DBObject

    module ClassMethods

        def column(name:, default: nil, primary_key: false, required: false)
            @columns ||= []
            @columns << [name, default, primary_key, required, name.to_s.gsub(/_([a-z])/) { $1.upcase }]
            attr_accessor name
            define_method(name) do
                instance_variable_get("@#{name}") || default
            end
            define_method("#{name}=") do |val|
                instance_variable_set("@#{name}", val)
            end
        end

        def table(name)
            @table_name = name
        end

        def primary_keys
            @columns.select { |column| column[2] }.map { |column| [column[0], column[4]] }
        end

        def from_row(row)
            object = self.new
            @columns.each do |column|
                val = row.find { |key, val| key.to_s.underscore.downcase == column[0].to_s }
                next if val.nil?
                object.send("#{column[0]}=", val[1])
            end
            object
        end

        def all(client)
            DBUtils.find(client, @table_name).map do |row|
                from_row(row)
            end
        end

        def delete_all(client)
            DBUtils.delete(client, @table_name, "1 = 1")
        end

        def delete(client, conditions)
            conditions.each do |key, val|
                raise "#{key} is not a valid column. Valid columns are #{@columns}" unless @columns
            end
            DBUtils.delete(client, @table_name, conditions.map { |key, val| "#{key.to_s.gsub(/_([a-z])/) { $1.upcase }} = '#{val}'" }.join(" AND "))
        end

        def find(client, conditions = {})
            conditions.each do |key, val|
                raise "#{key} is not a valid column. Valid columns are #{@columns.map{|c| c[0]}}" unless @columns.map { |column| column[0] }.include?(key)
            end
            DBUtils.find(client, @table_name, *conditions.map { |key, val| "#{key.to_s.gsub(/_([a-z])/) { $1.upcase }} = '#{val}'" }).map do |row|
                from_row(row)
            end
        end

        def find_raw(client, conditions = [], order: nil)
            DBUtils.find(client, @table_name, *conditions, order: order).map do |row|
                from_row(row)
            end
        end

        def find_one(client, conditions)
            res = find(client, conditions)
            raise "Found multiple results for #{table_name} with #{conditions}" if res.count > 1
            res.first
        end

        def find_one_raw(client, conditions, order: nil)
            res = find_raw(client, conditions, order: order)
            raise "Found multiple results for #{table_name} with #{conditions}" if res.count > 1
            res.first
        end

        def columns
            @columns
        end

        def table_name
            @table_name
        end
    end

    def self.included(base)
        base.extend(ClassMethods)
    end

    def columns
        columns = {}
        self.class.columns.each do |column|
            current = self.send(column[0])
            next if current == column[1] && current.nil?
            columns[column[4]] = current
        end
        columns
    end

    def is_identifiable?
        if self.class.primary_keys.empty?
            false
        else
            self.class.primary_keys.all? { |key| !self.send(key[0]).nil? }
        end
    end

    def save(client)
        self.class.columns.each do |column|
            raise "Cannot save object with required column #{column[0]} set to nil" if column[3] && self.send(column[0]).nil?
        end
        if is_identifiable?
            where = self.class.primary_keys.map { |key| "#{key[1]} = '#{self.send(key[0])}'" }.join(" AND ")
            DBUtils.update(client, self.class.table_name, where, columns)
            post_save(client)
        else
            pre_create(client)
            DBUtils.insert(client, self.class.table_name, columns)
            post_create(client)
        end
    end

    def pre_create(client)
        # Overridable
    end

    def post_create(client)
        # Overridable
    end

    def post_save(client)
        res = DBUtils.find_one(client, self.class.table_name, *self.class.primary_keys.map { |key| "#{key[1]} = '#{self.send(key[0])}'" })
        raise "Object not found after save" if res.nil?
        res = res.map { |key, val| [key.to_s.downcase, val] }.to_h
        self.class.columns.each do |column|
            send("#{column[0]}=", res[column[4].to_s.downcase])
        end
    end

    def delete(client)
        raise "Cannot delete object that is not identifiable" unless is_identifiable?
        where = self.class.primary_keys.map { |key| "#{key[1]} = '#{self.send(key[0])}'" }
        DBUtils.delete(client, self.class.table_name, where)
    end

    def to_s
        "#{self.class.table_name} #{columns}"
    end
end