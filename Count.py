A = []
statistic_A = {}
for host in A:
     if host not in statistic_A:
          statistic_A[host] = 1
     else:
          statistic_A[host] += 1
for host in statistic_A:
     print host, statistic_A[host]

