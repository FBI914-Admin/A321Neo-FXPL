include('EWD_msgs/common.lua')

--
-- Timers
--
timer_2nd_engine_on = sasl.createTimer()
timer_2nd_engine_on_started = false

--
-- Messages
--

Message_TO_AUTOBRK = {
    text = function(self)
        if (get(Autobrakes) == 3) then
            return "    AUTO BRK MAX"
        else
            return "    AUTO BRK..........MAX"
        end
    end,

    color = function(self)
        if (get(Autobrakes) == 3) then
            return COL_INDICATION
        else
            return COL_ACTIONS
        end
    end,

  is_active = function(self)
      return true -- Always active when group is active
  end
}

Message_TOLDG_SIGNS = {
    text = function(self)
        if (get(Seatbelts) ~= 0 and get(NoSmoking) ~= 0) then
            return "    SIGNS ON"
        else
            return "    SIGNS..............ON"
        end
    end,

    color = function(self)
        if (get(Seatbelts) ~= 0 and get(NoSmoking) ~= 0) then
            return COL_INDICATION
        else
            return COL_ACTIONS
        end
    end,

  is_active = function(self)
      return true -- Always active when group is active
  end
}

Message_TOLDG_CABIN = {
    text = function(self)
        if (get(CabinIsReady) == 1) then
            return "    CABIN CHECK"
        else
            return "    CABIN...........CHECK"
        end
    end,

    color = function(self)
        if (get(CabinIsReady) == 1) then
            return COL_INDICATION
        else
            return COL_ACTIONS
        end
    end,

  is_active = function(self)
      return true -- Always active when group is active
  end
}

Message_TOLDG_SPLRS = {
    text = function(self)
        if (get(Speedbrake_handle_ratio) < 0) then
            return "    SPLRS ARM"
        else
            return "    SPLRS.............ARM"
        end
    end,

    color = function(self)
        if (get(Speedbrake_handle_ratio) < 0) then
            return COL_INDICATION
        else
            return COL_ACTIONS
        end
    end,

  is_active = function(self)
      return true -- Always active when group is active
  end
}

Message_TO_FLAPS = {
    text = function(self)
        if (get(Flaps_handle_ratio) > 0 and get(Flaps_handle_ratio) < 0.5) then -- todo check values
            return "    FLAPS T.O."
        else
            return "    FLAPS............T.O."
        end
    end,

    color = function(self)
        if (get(Flaps_handle_ratio) > 0 and get(Flaps_handle_ratio) < 0.5) then -- todo check values
            return COL_INDICATION
        else
            return COL_ACTIONS
        end
    end,

  is_active = function(self)
      return true -- Always active when group is active
  end
}

Message_LDG_GEAR = {
    text = function(self)
        if (get(Front_gear_deployment) == 1 and get(Left_gear_deployment) == 1 and get(Right_gear_deployment) == 1) then 
            return "    LDG GEAR DN"
        else
            return "    LDG GEAR...........DN"
        end
    end,

    color = function(self)
        if (get(Front_gear_deployment) == 1 and get(Left_gear_deployment) == 1 and get(Right_gear_deployment) == 1) then 
            return COL_INDICATION
        else
            return COL_ACTIONS
        end
    end,

  is_active = function(self)
      return true -- Always active when group is active
  end
}

Message_LDG_FLAPS = {

    text = function(self)
        if get(FBW_status) < 2 then -- alternate or direct law
            if (get(Flaps_handle_ratio) > 0.6 and get(Flaps_handle_ratio) <= 0.8) then -- TODO check values
                return "    FLAPS CONF 3"
            else
                return "    FLAPS..........CONF 3"
            end
        else    -- normal law
            if (get(Flaps_handle_ratio) > 0.8 and get(Flaps_handle_ratio) <= 1) then -- TODO check values
                return "    FLAPS FULL"
            else
                return "    FLAPS............FULL"
            end
        end
        
    end,

    color = function(self)
         if get(FBW_status) < 2 then -- alternate or direct law
            if (get(Flaps_handle_ratio) > 0.6 and get(Flaps_handle_ratio) <= 0.8) then -- TODO check values
                return COL_INDICATION
            else
                return COL_ACTIONS
            end
        else    -- normal law
            if (get(Flaps_handle_ratio) > 0.8 and get(Flaps_handle_ratio) <= 1) then -- TODO check values
                return COL_INDICATION
            else
                return COL_ACTIONS
            end
        end
    end,

  is_active = function(self)
      return true -- Always active when group is active
  end
}

Message_TO_CONFIG = {
    
    text = function(self)
        if get(TO_Config_is_ready) == 1 then
            return "    T.O. CONFIG NORMAL"
        else
            return "    T.O. CONFIG......TEST"
        end
    end,

    color = function(self)
        if get(TO_Config_is_ready) == 1 then
            return COL_INDICATION
        else
            return COL_ACTIONS
        end
    end,

  is_active = function(self)
      return true
  end
}

--
-- Message groups
--

MessageGroup_MEMO_TAKEOFF = {

    shown = false,

    text  = function(self)
                return "T.O"
            end,
    color = function(self)
                return COL_INDICATION
            end,

    priority = PRIORITY_LEVEL_MEMO,

    messages = {
        Message_TO_AUTOBRK,
        Message_TOLDG_SIGNS,
        Message_TOLDG_CABIN,
        Message_TOLDG_SPLRS,
        Message_TO_FLAPS,
        Message_TO_CONFIG
    },

    -- Method to check if this message group is active
    is_active = function(self)
        -- Active after 2 minutes from the second engine start this message is enabled
        if (get(Engine_1_avail) == 1 and get(Engine_2_avail) == 1) then
            if not timer_2nd_engine_on_started then
                sasl.startTimer(timer_2nd_engine_on)
                timer_2nd_engine_on_started = true
            else
                if (get(EWD_flight_phase) == PHASE_1ST_ENG_ON) and sasl.getElapsedSeconds(timer_2nd_engine_on) > 120 then
                    set(EWD_is_to_memo_showed, 1)
                    return true
                end
            end        
        else    
            if timer_2nd_engine_on_started then -- Someone powered off an engine here
                sasl.stopTimer(timer_2nd_engine_on)
                timer_2nd_engine_on_started = false
            end        
        end

        -- TODO Check TO CONFIG BUTTON

        set(EWD_is_to_memo_showed, 0)
        return false 
    end,

    -- Method to check if this message is currently inhibithed
    is_inhibited = function(self)
        return not (get(EWD_flight_phase) == PHASE_1ST_ENG_ON) 
    end

}


MessageGroup_MEMO_LANDING = {

    shown = false,

    text  = function(self)
                return "LDG"
            end,
    color = function(self)
                return COL_INDICATION
            end,

    priority = PRIORITY_LEVEL_MEMO,

    messages = {
        Message_LDG_GEAR,
        Message_TOLDG_SIGNS,
        Message_TOLDG_CABIN,
        Message_TOLDG_SPLRS,
        Message_LDG_FLAPS,
    },

    -- Method to check if this message group is active
    is_active = function(self)
        -- Active if in phase 7 or below 2000ft if LDG down, until below 80 kts
        if (get(Gear_handle) == 1 and get(EWD_flight_phase) == PHASE_AIRBONE and get(Capt_ra_alt_ft) < 2000) or (get(EWD_flight_phase) == PHASE_FINAL) or (get(EWD_flight_phase) == PHASE_TOUCHDOWN) then
            set(EWD_is_ldg_memo_showed, 1)
            return true
        else
            set(EWD_is_ldg_memo_showed, 0)
            return false 
        end
    end,

    -- Method to check if this message is currently inhibithed
    is_inhibited = function(self)
        -- Never inhibited
        return false
    end

}
