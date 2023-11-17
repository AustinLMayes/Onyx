# Playback page
class Onyx::Matrix
    include Onyx::DBObject

    table "MatrixV2"

    column name: :matrix_page, primary_key: true
    column name: :matrix_pos_x, primary_key: true
    column name: :matrix_pos_y, primary_key: true, default: -1
    column name: :matrix_cue_list_id, required: true
    column name: :over_ride_cue_list, default: 0
    column name: :function_assignments, default: nil

    def post_create(client)
        res = DBUtils.find_one(client, "MatrixV2", "MatrixPage = #{matrix_page} AND MatrixPosX = #{matrix_pos_x} AND MatrixPosY = #{matrix_pos_y}")
        raise "Object not found after save" if res.nil?
        res = res.map { |key, val| [key.to_s.downcase, val] }.to_h
        self.class.columns.each do |column|
            send("#{column[0]}=", res[column[4].to_s.downcase])
        end
    end

    def is_identifiable?
        false
    end

    def pre_create(client)
        Onyx::Matrix.delete(client, matrix_page: matrix_page, matrix_pos_x: matrix_pos_x, matrix_pos_y: matrix_pos_y)
    end
end