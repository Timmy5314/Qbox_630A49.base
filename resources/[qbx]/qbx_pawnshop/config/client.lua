return {
    useTarget = GetConvar('UseTarget', 'true') == 'true',
    useTimes = false, -- Set to false if you want the pawnshop open 24/7
    timeOpen = 7,     -- Opening Time
    timeClosed = 17,  -- Closing Time
    sendMeltingEmail = true,
}