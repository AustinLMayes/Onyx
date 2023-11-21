
class Onyx::Cuelist
    include Onyx::DBObject

    table "CueListsV3"

    column name: :cue_list_id, primary_key: true
    column name: :vis_cue_list_id, required: true
    column name: :cue_list_name, required: true
    column name: :comment, default: ''
    column name: :display_mode, default: 1
    column name: :amount_rows, default: 1
    column name: :split_timings, default: 0
    column name: :tracking, default: 1
    column name: :over_ride_cue_list, default: 0
    column name: :default_release_time, default: 0
    column name: :cue_fading_speed, default: 100
    column name: :options_data, default: nil
    column name: :chase_rate, default: 800
    column name: :chase_fade, default: 100
    column name: :auto_release_mode, default: 2500
    column name: :time_code_mode, default: nil
    column name: :programmer_overridable, default: 1
    column name: :priority_level, default: 50
    column name: :chase_direction, default: 0
    column name: :chase_use_timing, default: 0
    column name: :ignore_global_release, default: 0
    column name: :rel_on_next_go, default: 0
    column name: :fader_trigger_level, default: 8
    column name: :go_swop_sub, default: 0
    column name: :cl_rate, default: 100
    column name: :htpcl, default: 0
    column name: :default_cl_fader_value, default: -1
    column name: :auto_start_cl, default: 0
    column name: :mark_mode, default: 0
    column name: :chase_tap_synch, default: 0
    column name: :chase_update_db, default: 0
    column name: :override_combined_cues, default: 0
    column name: :tc_obey_tc_range, default: 1
    column name: :tc_wait_for_change, default: 1
    column name: :ms_cout_mode, default: nil
    column name: :cuelist_appearance, default: nil
    column name: :flash_data, default: nil

    def self.from_name(client, name)
        find_one(client, cue_list_name: name)
    end

    def pre_create(client)
        self.cue_list_id = client.execute("SELECT NEXT VALUE FOR [dbo].[SeqCueListId]").first[""]
    end

    def self.human_to_onyx_id(num)
        num * 10000
    end

    def self.from_id(client, id)
        find_one(client, cue_list_id: id)
    end

    def self.next_available_vis_id(client, start)
        res = find_raw(client, "VisCueListID >= #{start}", order: "VisCueListID ASC").last
        res.nil? ? start : res.vis_cue_list_id + human_to_onyx_id(1)
    end

    def post_create(client)
        res = DBUtils.find_one(client, "CueListsV3", "VisCueListID = #{vis_cue_list_id}")
        raise "Cue list not found" if res.nil?
        res = res.map { |key, val| [key.to_s.downcase, val] }.to_h
        self.class.columns.each do |column|
            send("#{column[0]}=", res[column[4].to_s.downcase])
        end
        raise "Cue list data not found" if @cue_list_id.nil?
    end

    def cues(client)
        Onyx::Cue.find(client, cue_list_id: cue_list_id)
    end

    def add_go_cue(client, name, comment: '', time: 2.5, row: nil, id: nil, macros: [])
        cue = Onyx::Cue.new
        cue.cue_list_id = cue_list_id
        row = row || cues(client).length + 1
        cue.row = row.to_i
        id = id
        if id.nil?
            if cues(client).empty?
                id = 1
            else
                id = (cues(client).map(&:cue_id).max / 10000) + 1
            end
        end
        cue.cue_id = (Onyx::Cuelist.human_to_onyx_id(id)).to_i
        cue.trigger_mode = Onyx::Cue::MODE_GO
        cue.cue_name = name
        cue.comment = comment
        cue.fade_in = Onyx::Cue.time_to_onyx(time)
        cue.macro_data = macros.join("\n") unless macros.empty?
        cue.save(client)
        cue
    end

    def add_wait_cue(client, name, wait_time, comment: '', time: 2.5, row: nil, id: nil, macros: [])
        cue = Onyx::Cue.new
        cue.cue_list_id = cue_list_id
        row = row || cues(client).length + 1
        cue.row = row.to_i
        id = id || (cues(client).map(&:cue_id).max / 10000) + 1
        cue.cue_id = (Onyx::Cuelist.human_to_onyx_id(id)).to_i
        cue.trigger_mode = Onyx::Cue::MODE_WAIT
        cue.cue_name = name
        cue.comment = comment
        cue.trigger_time = Onyx::Cue.time_to_onyx(wait_time)
        cue.fade_in = Onyx::Cue.time_to_onyx(time)
        cue.macro_data = macros.join("\n") unless macros.empty?
        cue.save(client)
        cue
    end

    def add_follow_cue(client, name, follow_time, comment: '', time: 2.5, row: nil, id: nil, macros: [])
        cue = Onyx::Cue.new
        cue.cue_list_id = cue_list_id
        row = row || cues(client).length + 1
        cue.row = row.to_i
        id = id || (cues(client).map(&:cue_id).max / 10000) + 1
        cue.cue_id = (Onyx::Cuelist.human_to_onyx_id(id)).to_i
        cue.trigger_mode = Onyx::Cue::MODE_FOLLOW
        cue.cue_name = name
        cue.comment = comment
        cue.trigger_time = Onyx::Cue.time_to_onyx(follow_time)
        cue.fade_in = Onyx::Cue.time_to_onyx(time)
        cue.macro_data = macros.join("\n") unless macros.empty?
        cue.save(client)
        cue
    end

    def move_to_archive(client)
        id = Onyx::Cuelist.next_available_vis_id(client, Onyx::Cuelist.human_to_onyx_id(300))
        self.vis_cue_list_id = id
        info "Moving #{cue_list_name} to #{vis_cue_list_id}"
        save(client)
    end
    
end