require 'common'

module DBUtils
    extend self

    def find(client, table, *conditions, order: nil)
        query = "SELECT * FROM #{table}"
        query += " WHERE #{conditions.join(' AND ')}" unless conditions.empty?
        query += " ORDER BY #{order}" unless order.nil?
        debug "Executing query: #{query}"
        client.execute(query)
    end
    
    def find_one(client, table, *conditions)
        res = find(client, table, *conditions)
        raise "Found multiple results for #{table} with #{conditions}" if res.count > 1
        res.first
    end
    
    def update(client, table, where, values)
        query = "UPDATE #{table} SET #{values.map{|k,v| "#{k} = '#{v}'"}.join(', ')} WHERE #{where}"
        debug "Executing query: #{query}"
        client.execute(query).do
    end
    
    def insert(client, table, values)
        query = "INSERT INTO #{table} (#{values.keys.join(',')}) VALUES (#{values.values.map{|v| "'#{v}'"}.join(',')})"
        debug "Executing query: #{query}"
        client.execute(query).insert
    end
    
    def delete(client, table, where)
        query = "DELETE FROM #{table} WHERE #{where}"
        debug "Executing query: #{query}"
        client.execute(query).do
    end
end