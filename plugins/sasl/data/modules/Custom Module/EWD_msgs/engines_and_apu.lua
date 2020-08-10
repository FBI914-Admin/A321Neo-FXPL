include('EWD_msgs/common.lua')

----------------------------------------------------------------------------------------------------
-- CAUTION: APU AUTO/EMER SHUT DOWN
----------------------------------------------------------------------------------------------------
Message_APU_AUTO_SHUT_DOWN = {
    text = function(self)
        return "    AUTO SHUT DOWN"
    end,

    color = function(self)
        return COL_CAUTION
    end,

    is_active = function(self)
      return get(FAILURE_Apu) == 6
    end
}

Message_APU_EMER_SHUT_DOWN = {
    text = function(self)
        return "    EMERG SHUT DOWN"
    end,

    color = function(self)
        return COL_CAUTION
    end,

    is_active = function(self)
      return get(FAILURE_Apu_fire) == 6
    end
}

Message_APU_MASTER_SWITCH_OFF = {
    text = function(self)
        return " - MASTER SW..........OFF"
    end,

    color = function(self)
        return COL_ACTIONS
    end,

  is_active = function(self)
      return get(Apu_start_position) ~= 0 
  end
}

MessageGroup_APU_SHUTDOWN = {

    shown = false,

    text  = function(self)
                return "APU"
            end,
    color = function(self)
                return COL_CAUTION
            end,

    sd_page = ECAM_PAGE_APU,

    priority = PRIORITY_LEVEL_2,

    messages = {
        Message_APU_AUTO_SHUT_DOWN,
        Message_APU_EMER_SHUT_DOWN,
        Message_APU_MASTER_SWITCH_OFF
    },

    -- Method to check if this message group is active
    is_active = function(self)
        return get(FAILURE_Apu) == 6 or get(FAILURE_Apu_fire) == 6
    end,

    -- Method to check if this message is currently inhibithed
    is_inhibited = function(self)
        return get(EWD_flight_phase) == PHASE_1ST_ENG_TO_PWR or get(EWD_flight_phase) == PHASE_ABOVE_80_KTS or
               get(EWD_flight_phase) == PHASE_LIFTOFF or get(EWD_flight_phase) == PHASE_FINAL or get(EWD_flight_phase) == PHASE_TOUCHDOWN
    end

}

----------------------------------------------------------------------------------------------------
-- WARNING: APU FIRE
----------------------------------------------------------------------------------------------------
Message_APU_FIRE = {
    text = function(self)
        return "    FIRE"
    end,

    color = function(self)
        return COL_WARNING
    end,

    is_active = function(self)
      return true
    end
}

Message_APU_FIRE_PB = {
    text = function(self)
        return " - APU FIRE P/B......PUSH"
    end,

    color = function(self)
        return COL_ACTIONS
    end,

    is_active = function(self)
      return true   -- TODO Datarefs
    end
}

Message_APU_AFTER_10_S = {
    text = function(self)
        return " . AFTER 10 SECONDS:"
    end,

    color = function(self)
        return COL_REMARKS
    end,

    is_active = function(self)
      return true   -- TODO Datarefs
    end
}

Message_APU_AGENT = {
    text = function(self)
        return " - AGENT............DISCH"
    end,

    color = function(self)
        return COL_ACTIONS
    end,

    is_active = function(self)
      return true   -- TODO Datarefs
    end
}

MessageGroup_APU_FIRE = {

    shown = false,

    text  = function(self)
                return "APU"
            end,
    color = function(self)
                return COL_WARNING
            end,

    sd_page = ECAM_PAGE_APU,
    
    land_asap = true,

    priority = PRIORITY_LEVEL_3,

    messages = {
        Message_APU_FIRE,
        Message_APU_FIRE_PB,
        Message_APU_AFTER_10_S,
        Message_APU_AGENT
    },

    is_active = function(self)
        return get(FAILURE_Apu_fire) == 6
    end,

    is_inhibited = function(self)
        return false
    end

}
