
tau_neg=tau_empTrunc(find(speed_for_FLP<0));
tau_0=tau_empTrunc(find(speed_for_FLP==0));
tau_3_9=tau_empTrunc(find(speed_for_FLP>=3&speed_for_FLP<9));
tau_9=tau_empTrunc(find(speed_for_FLP>=9));

intensity_neg=photoncount(find(speed_for_FLP<0));
intensity_0=photoncount(find(speed_for_FLP==0));
intensity_3_9=photoncount(find(speed_for_FLP>=3&speed_for_FLP<9));
intensity_9=photoncount(find(speed_for_FLP>=9));