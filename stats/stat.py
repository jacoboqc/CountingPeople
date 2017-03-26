
# coding: utf-8

# # CountingPeople
#
# ## Static statistics
# ### Description
#
# The following code generates some statistics used to annalyse our system.

# ### Requisites
#
#     - Python 3.6
#     - Pandas
#     - Matplotlib
#     - numpy
#     - Ipython
#

# In[119]:

import pandas as pd
import numpy as np
import matplotlib
import matplotlib.dates as mdates
import matplotlib.pyplot as plt
from datetime import datetime
from tabulate import tabulate
import requests
import io
import scipy
from scipy.stats import mode
# ### Functions
#
#     - read_csv: Next function read the csv and parse it to dataFrame

# In[120]:


def read_csv(file):
    csv = pd.read_csv(file)
    csv['time'] = pd.to_datetime(csv['time'], format='%Y/%m/%d-%H:%M:%S')
    csv = csv.set_index(pd.DatetimeIndex(csv['time']))
    csv = csv.sort_values(['time'], ascending=[True])
    return csv


def consult_api():
    url = "http://localhost:3000/macs"
    myReq = requests.get(url, headers={'Accept': 'text/csv'})
    if myReq.ok:
        return read_csv(io.StringIO(myReq.content.decode('utf-8')))
#     - mac_occurs: plot the mac occurs along the time

# In[121]:


def mac_occurs(df, show):
    g = df.groupby(["mac", "time"], as_index=False)
    d = g.size()
    plt.axes().axes.set_xticklabels([])
    plt.title('Occurs per mac')
    plt.xlabel("MACs")
    plt.ylabel("Occurs")
    plt.tight_layout()
    ax = d.plot(x='mac', y=d, kind='bar')
    ax.set_xticklabels([])
    plt.savefig('mac_occurs.pdf', bbox_inches="tight")
    if show is True:
        plt.show()
    plt.gcf().clear()


#     - origin_activity: plot all the activity on the system.

# In[122]:

def origin_activity(df, show):
    g = df.groupby(pd.TimeGrouper(freq='45s')).size()
    g.plot(x='time', y=g, kind='bar')
    plt.title('Origin activity on the system')
    plt.xlabel("Time")
    plt.ylabel("Origin")
    plt.tight_layout()
    plt.savefig("origin_activity.pdf", bbox_inches="tight")
    if show is True:
        plt.show()
    plt.gcf().clear()


#     - mac_activity: plots the activity each mac along the time

# In[123]:

"""
Deberia estar mal, pero da el mismo resultado que mac_activity
"""


def mac_activity_bad(df, show):
    df = df.drop(['type', 'ID', 'device'], axis=1)
    g = df.groupby([
        pd.TimeGrouper(freq='45s')], as_index=True)

    df = pd.DataFrame(columns=['time', 'macs'])
    for name, group in g:
        df.loc[len(df)] = [name, len(group.groupby(['mac']))]

    df.plot(x='time', y='macs', kind='bar',
            title='Mac activity on the system', legend=False)
    plt.title('Activity on the system')
    plt.xlabel("Time")
    plt.ylabel("Activity")
    plt.tight_layout()
    plt.savefig("mac_activity_bad.pdf", bbox_inches="tight")
    if show is True:
        plt.show()
    plt.gcf().clear()


# In[124]:

def mac_activty_good(df, show):
    csv_1 = df.drop(['type', 'ID', 'device'], axis=1)
    csv_1 = csv_1.set_index(pd.DatetimeIndex(csv_1['time']))
    group_by_mac_in_time = csv_1.groupby(['mac'], as_index=False).first()
    group_by_mac_in_time = group_by_mac_in_time.set_index(
        pd.DatetimeIndex(group_by_mac_in_time['time']))
    group_by_mac_in_time = group_by_mac_in_time.groupby(
        [pd.TimeGrouper(freq='45s')], as_index=False).size()

    plt.title('Activity on the system')
    plt.xlabel("Time")
    plt.ylabel("MAC")
    group_by_mac_in_time.plot(kind='bar')
    plt.savefig("mac_activity_good.pdf", bbox_inches="tight")
    plt.tight_layout()
    if show is True:
        plt.show()
    plt.gcf().clear()


#     - mac_system: Plot the acumulated number of macs in the system

# In[125]:

def mac_system(df, show):
    csv_1 = df.drop(['type', 'ID', 'device'], axis=1)
    csv_1 = csv_1.set_index(pd.DatetimeIndex(csv_1['time']))
    group_by_mac_in_time = csv_1.groupby(['mac'], as_index=False).first()
    group_by_mac_in_time = group_by_mac_in_time.set_index(
        pd.DatetimeIndex(group_by_mac_in_time['time']))
    group_by_mac_in_time = group_by_mac_in_time.groupby(
        [pd.TimeGrouper(freq='45s')], as_index=False).size().cumsum()

    plt.title('Mac on the system')
    plt.xlabel("Time")
    plt.ylabel("Nº Macs")
    group_by_mac_in_time.plot()
    plt.savefig("mac_system.pdf", bbox_inches="tight")
    if show is True:
        plt.show()
    plt.gcf().clear()


def T_burst(df, show):
    df = df.drop(['ID', 'device'], axis=1)
    df = df[~df['type'].isin(['random'])]
    df = df.groupby(['mac'], as_index=True)
    df_t = pd.DataFrame(columns=['mac', 'average'])

    for index, mac in df:
        t_average = 0
        t_previous = datetime.now()

        # Descartamos las macs que solo tienen una ocurrencia
        if(len(mac['time'])) != 1:
            i = 0
            for idx, time in enumerate(mac['time']):
                if idx == 0:
                    t_previous = time

                else:
                    diff = (time - t_previous).total_seconds()
                    # solo se tiene en cuenta para la media, las macs que
                    # llegan en segundos diferentes
                    if diff != float(0):
                        t_average += diff
                        t_previous = time
                        i += 1

                # realizamos la media
                if idx is len(mac) - 1:
                    if i == 0:
                        i = 1
                    t_average = t_average / i
                    df_t.loc[len(df_t)] = [index, t_average]

    # Descartamos las macs cuyo average es 0 => emisiones seguidas en el tiempo
    df_t = df_t[~df_t['average'].isin([0.0])]
    
    # Plot del tiempo de cada mac
    ax = df_t.plot(x=df_t['mac'])
    ax.set_xticklabels([])
    plt.title('Time MAC burst')
    plt.xlabel("Mac")
    plt.ylabel("Burst")
    plt.savefig("time_mac_burst.pdf", bbox_inches="tight")
    
    if show is True:
        plt.show()
    plt.gcf().clear()
    
    ###########       PLOT DISTRIBUCION  ########
    fig, axes = plt.subplots(nrows=2, ncols=1)
    df_t.plot(y='average', kind='hist', rot=0, ax=axes[0], legend=False)
    df_t.plot(y='average', kind='kde', ax=axes[1], legend=False)
    axes[0].set_xlim(xmin=0, xmax=500)
    axes[1].set_xlim(xmin=0, xmax=500)
    plt.xlabel("Time")
    plt.savefig("time_burst.pdf", bbox_inches="tight")
    
    if show is True:
        plt.show()
    plt.gcf().clear()

    ###########        PLOT DISTRIBUCION AGRUPADA ########
    # creamos 10 grupos en base a ese global
    bins = np.linspace(0, df_t.average.max(), 10)
    # dividimos en categorias
    df_t['category'] = pd.cut(df_t['average'], bins)
    count = df_t.groupby(['category']).size()

    fig, axes = plt.subplots(nrows=2, ncols=1)
    count.plot(kind='hist', ax=axes[0])
    count.plot(kind='kde', ax=axes[1])
    axes[0].set_xlim(xmin=0)
    axes[1].set_xlim(xmin=0)
    plt.xlabel("Time")
    plt.savefig("time_categorize_burst.pdf", bbox_inches="tight")
    
    if show is True:
        plt.show()
    plt.gcf().clear()

# ### Example

# ### Example
#
# Main program example with results


# In[126]:
df = consult_api()
#df = read_csv('Captura_Peritos.csv')


T_burst(df, False)

mac_activty_good(df, False)


# In[127]:

mac_activty_good(df, False)


# In[128]:

mac_activity_bad(df, False)


# In[129]:

origin_activity(df, False)


# In[130]:

mac_occurs(df, False)

