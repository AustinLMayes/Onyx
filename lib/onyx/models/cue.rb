class Onyx::Cue
    include Onyx::DBObject

    MODE_GO = 4
    MODE_WAIT = 5
    MODE_FOLLOW = 6

    table "CueValuesV3"

    column name: :cue_list_id
    column name: :row
    column name: :mode, default: 0
    column name: :cue_id
    column name: :cue_name, required: true
    column name: :comment, default: ''
    column name: :trigger_mode, default: 4
    column name: :trigger_time
    column name: :fade_mode
    column name: :fade_curve
    column name: :cue_split_timings, default: 0
    column name: :delay_in, default: 0
    column name: :delay_out, default: -1
    column name: :fade_in, default: 250
    column name: :fade_out, default: -1
    column name: :goto_data, default: nil
    column name: :link_data, default: nil
    column name: :macro_data, default: nil
    column name: :blocking_cue, default: 0
    column name: :only_this_cue, default: 0
    column name: :amount_values, default: 0
    column name: :channel_values, default: nil
    column name: :amount_values_track_through, default: 0
    column name: :channel_values_track_through, default: nil
    column name: :amount_values_track_full, default: 0
    column name: :channel_values_track_full, default: nil
    column name: :tracking_state, default: 0
    column name: :amount_timing_values, default: 0
    column name: :timing_values, default: nil
    column name: :min_fade_in, default: -1
    column name: :max_fade_in, default: -1
    column name: :min_delay_in, default: -1
    column name: :max_delay_in, default: -1
    column name: :time_code_time_v2, default: -1
    column name: :cue_id_guid, primary_key: true
    column name: :min_fade_out, default: -1
    column name: :max_fade_out, default: -1
    column name: :min_delay_out, default: -1
    column name: :max_delay_out, default: -1
    column name: :fade_path, default: 0
    column name: :cue_mark, default: 0
    column name: :cue_mark_delay, default: -1
    column name: :cue_mark_fade, default: -1
    column name: :from_fader_value, default: -1
    column name: :to_fader_value, default: -1

    def post_create(client)
        res = DBUtils.find_one(client, "CueValuesV3", "CueListID = '#{cue_list_id}'", "Row = #{row}")
        raise "Cue not found" if res.nil?
        res = res.map { |key, val| [key.to_s.downcase, val] }.to_h
        self.class.columns.each do |column|
            send("#{column[0]}=", res[column[4].to_s.downcase])
        end
        raise "Cue data not found" if @cue_id_guid.nil?
    end

    def macros
        data = macro_data || ''
        macro_data.split("\n")
    end

    def add_macro(macro)
        self.macro_data = '' if macro_data.nil?
        self.macro_data += "\n" unless macro_data.empty?
        self.macro_data += macro
    end

    def remove_macro(macro)
        self.macro_data = macro_data.split("\n").reject { |m| m == macro }.join("\n")
    end

    def clear_macros
        self.macro_data = ''
    end

    def self.time_to_onyx(time)
        return nil if time.nil?
        (time * 100).to_i
    end
end
