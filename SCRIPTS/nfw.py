#!/usr/bin/env python
# coding: utf-8

# In[ ]:

from __future__ import division
import sys
import numpy as np
import matplotlib.pyplot as plt
from scipy.optimize import curve_fit
np.seterr(divide='ignore')

skip_size = 1
pmass = 0.413582
rhoc = 1.4e-8

name = sys.argv[1]
snap = sys.argv[2]
cut = sys.argv[3]

# pdata contains all particles in the cutout
with open('/home/rgudapati/Documents/auto/HALOS/snap%d_halo%d.idposgrp' % (int(snap), int(cut))) as f:
    pdata = []
    for line in f:
        pdata.append([ float(x) for x in line.split()])
        
# hdata contains all particles in the main halo
with open('/home/rgudapati/Documents/auto/HALOS/%s.pos' % name) as f:
    hdata = []
    for line in f:
        hdata.append([ float(x) for x in line.split()])
    
# positions of all particles in cutout
xpos = [ x[1] for x in pdata]
ypos = [ x[2] for x in pdata]
zpos = [ x[3] for x in pdata]

# positions of all particles in halo
hxpos = [ x[0] for x in hdata]
hypos = [ x[1] for x in hdata]
hzpos = [ x[2] for x in hdata]

#----------------------------------------------

# find virial radius of halo

hmass = len(hdata)*pmass
rvir = (3.0*hmass/(4.0*np.pi*200.0*rhoc))**(1/3)
endrange = np.log10(rvir)

# find com of halo

xcom = pmass * (sum(hxpos)) / hmass
ycom = pmass * (sum(hypos)) / hmass
zcom = pmass * (sum(hzpos)) / hmass

#-----------------------------------------------

distance = []
for i in range(len(xpos)):
    dx = xpos[i] - xcom
    dy = ypos[i] - ycom
    dz = zpos[i] - zcom
    distance.append(np.sqrt(dx**2.0+dy**2.0+dz**2.0))
    
x = np.logspace(2.1,endrange,num=50,dtype=float,endpoint=True)

V = []
for i in range(len(x)-1):
    V.append(4*np.pi*(x[i+1]-x[i]))
    
V.insert(0,0)

y = []
for i in range(len(x)):
    y.append(0)
    
avg = []
for i in range(len(x)):
    avg.append(0)
    
for i in range(len(distance)):
    for j in range(len(x)-1):
        if ((distance[i] > x[j]) and (distance[i] <= x [j+1])):
            y[j] = y[j] + 1
            avg[j] += distance[i]
            
for j in range(len(avg)):
    if y[j] != 0 and avg[j] != 0:
        avg[j] = avg[j] / y[j]
    else:
        avg[j] = x[j]
        
for i in range(len(y)):
    if avg[i] != 0:
        y[i] = y[i] * skip_size/(V[i]*avg[i]**2)

y = np.nan_to_num(y)
y[0] = y[1]

def nfw(ri, rs, ps):
    ret = ps / ((ri/rs)*(1+(ri/rs))*(1+(ri/rs)))
    return ret

try:
    popt, pcov = curve_fit(nfw, x, y)
except RuntimeError:
    with open("nfwparams","a") as f:
        f.write("no fit\n")
else:
    rs = popt[0]
    rhos = popt[1]
    ns = nfw(x,*popt)
    c = rvir / rs
    
    with open("nfwparams","a") as f:
        f.write("%f %f %f %f (%d) \n" % (rvir, rs, rhos, c, int(snap)))
