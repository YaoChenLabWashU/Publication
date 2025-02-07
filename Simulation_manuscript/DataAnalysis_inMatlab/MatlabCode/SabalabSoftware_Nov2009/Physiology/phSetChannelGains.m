function phSetChannelGains
	global state
	
	if state.phys.settings.channelType0>1
		if state.phys.settings.currentClamp0
			state.phys.internal.channelGains(1)=state.phys.settings.mVPerVIn0/state.phys.settings.inputGain0;
			state.phys.internal.channelGains(3)=state.phys.settings.pAPerVIn0;
		else
			state.phys.internal.channelGains(1)=state.phys.settings.pAPerVIn0/state.phys.settings.inputGain0;
			state.phys.internal.channelGains(3)=state.phys.settings.mVPerVIn0;
		end
	end
			
	if state.phys.settings.channelType1>1
		if state.phys.settings.currentClamp1
			state.phys.internal.channelGains(2)=state.phys.settings.mVPerVIn1/state.phys.settings.inputGain1;
			state.phys.internal.channelGains(4)=state.phys.settings.pAPerVIn1;
		else
			state.phys.internal.channelGains(2)=state.phys.settings.pAPerVIn1/state.phys.settings.inputGain1;
			state.phys.internal.channelGains(4)=state.phys.settings.mVPerVIn1;
		end
	end