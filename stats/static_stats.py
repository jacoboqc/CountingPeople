
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

# In[8]:

import pandas as pd
import numpy as np
import matplotlib
import matplotlib.dates as mdates
import matplotlib.pyplot as plt
from datetime import datetime
from IPython.display import HTML
from tabulate import tabulate
import requests
import io

HTML('''<script>
code_show=true; 
function code_toggle() {
 if (code_show){
 $('div.input').hide();
 } else {
 $('div.input').show();
 }
 code_show = !code_show
} 
$( document ).ready(code_toggle);
</script>
The raw code for this IPython notebook is by default hidden for easier reading.
To toggle on/off the raw code, click <a href="javascript:code_toggle()">here</a>.''')


# ### Functions
#
#     - read_csv: read the csv and parse it to dataFrame

# In[9]:

def read_csv(file):
    csv = pd.read_csv(file)
    csv['time'] = pd.to_datetime(csv['time'], format='%Y/%m/%d-%H:%M:%S')
    csv = csv.set_index(pd.DatetimeIndex(csv['time']))
    csv = csv.sort_values(['time'], ascending=[True])
    return csv


#     - consult_api: call to the API, get the csv and parse it to dataFrame

# In[10]:

def consult_api():
    url = "localhost:3000/macs/interval?start=2017/04/06-09:00:00"
    myReq = requests.get(url, headers={'Accept': 'text/csv'})
    if myReq.ok:
        return read_csv(io.StringIO(myReq.content.decode('utf-8')))


#     - mac_occurs: plot the mac occurs along the time

# In[11]:

def mac_occurs(df, show):
    g = df.groupby(["mac"], as_index=False)
    d = g.size()

    plot(d, 'mac', None, 'Ocurrs per mac', 'MACs', 'Occurs', None,
         None, None, None, show, None, 'bar', 'mac_occurs.pdf')


#     - origin_activity: plot all the activity on the system.

# In[12]:


def origin_activity(df, show):
    g = df.groupby(pd.TimeGrouper(freq='45s')).size()

    plot(g, 'time', None, 'Origin activity on the system', 'Time', 'Origin',
         None, None, None, None, show, None, 'bar', 'origin_activity.pdf')

#     - mac_activity: plots the activity each mac along the time

# In[13]:


"""
It should be wrong but gives the same result that mac_activity_good
"""


def mac_activity_bad(df, show):
    df = df.drop(['type', 'ID', 'device'], axis=1)
    g = df.groupby([pd.TimeGrouper(freq='45s')], as_index=True)

    df = pd.DataFrame(columns=['time', 'macs'])
    for name, group in g:
        df.loc[len(df)] = [name, len(group.groupby(['mac']))]

    plot(df, 'time', 'macs', 'Activity on the system', 'Time', 'Activity',
         None, None, None, None, show, None, 'bar', 'mac_activity_bad.pdf')

# In[14]:


def mac_activty_good(df, show):
    df = df.drop(['type', 'ID', 'device'], axis=1)
    df = df.set_index(pd.DatetimeIndex(df['time']))
    g = df.groupby(['mac'], as_index=False).first()
    g = g.set_index(pd.DatetimeIndex(g['time']))
    g = g.groupby([pd.TimeGrouper(freq='45s')], as_index=False).size()

    plot(g, 'time', 'macs', 'Activity on the system', 'Time', 'Activity',
         None, None, None, None, show, None, 'bar', 'mac_activity_good.pdf')

#     - mac_system: Plot the acumulated number of macs in the system

# In[15]:


def mac_system(df, show):
    df = df.drop(['type', 'ID', 'device'], axis=1)
    df = df.set_index(pd.DatetimeIndex(df['time']))
    g = df.groupby(['mac'], as_index=False).first()
    g = g.set_index(pd.DatetimeIndex(g['time']))
    g = g.groupby([pd.TimeGrouper(freq='45s')], as_index=False).size().cumsum()

    plot(g, None, None, 'Macs on the system', 'Time', 'Nº Macs',
         None, None, None, None, show, None, None, 'mac_system.pdf')


#     - T_burst: Plot the time between burst for each mac, and plot the
# average time between burst.

# In[16]:


def T_burst(df, show):
    df = df.drop(['ID', 'device'], axis=1)
    df = df[~df['type'].isin(['random'])]
    df = df.groupby(['mac'], as_index=True)
    df_t = pd.DataFrame(columns=['mac', 'average'])

    for index, mac in df:
        t_average = 0
        t_previous = datetime.now()

        # MACs with only one occurrency are discarted
        if(len(mac['time'])) != 1:
            i = 0
            for idx, time in enumerate(mac['time']):
                if idx == 0:
                    t_previous = time

                else:
                    diff = (time - t_previous).total_seconds()
                    # macs which are received in the same seconds are discarted
                    if diff != float(0):
                        t_average += diff
                        t_previous = time
                        i += 1

                # average
                if idx is len(mac) - 1:
                    if i == 0:
                        i = 1
                    t_average = t_average / i
                    df_t.loc[len(df_t)] = [index, t_average]

    # macs with average equal to 0 are discarted =>
    # consecutive emits by the same device
    df_t = df_t[~df_t['average'].isin([0.0])]

    # Plot burts time for each mac
    plot(df_t, 'mac', None, 'Time MAC burst', 'Mac', 'Burst',
         None, None, None, None, show, [], None, 'time_mac_burst.pdf')

    #       PLOT DISTRIBUTION  ########
    fig, axes = plt.subplots(nrows=2, ncols=1)
    df_t.plot(y='average', kind='hist', rot=0, ax=axes[0], legend=False)
    df_t.plot(y='average', kind='kde', ax=axes[1], legend=False)
    axes[0].set_xlim(xmin=0)
    axes[1].set_xlim(xmin=0)
    plt.xlabel("Time")
    plt.savefig("time_burst.pdf", bbox_inches="tight")

    if show is True:
        plt.show()
    plt.gcf().clear()

    #       PLOT DISTRIBUTION grouped ########
    # macs are agrupated in 10 groups
    bins = np.linspace(0, df_t.average.max(), 10)
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


def plot(data, xVar, yVar, title, xlabel, ylabel, xlimMin, xlimMax,
         ylimMin, ylimMax, shouldPlot, xtick, kind, pdfName):

    plt.title(title)
    plt.xlabel(xlabel)
    plt.ylabel(ylabel)
    plt.tight_layout()
    if kind is not None:
        ax = data.plot(x=xVar, y=yVar, kind=kind, legend=False)
    else:
        ax = data.plot(x=xVar, y=yVar, legend=False)

    if xtick is not None:
        ax.set_xticklabels(xtick)
    plt.savefig(pdfName, bbox_inches="tight")

    if shouldPlot is True:
        plt.show()

    plt.gcf().clear()


def T_system(df, show):
    df = df.drop(['ID', 'device'], axis=1)
    df = df[~df['type'].isin(['random'])]
    df = df.groupby(['mac'], as_index=False).filter(lambda x: len(x) > 1)
    g = df.groupby(['mac'], as_index=False)
    gIN = g.first()
    gOUT = g.last()

    dfInOut = pd.DataFrame(columns=['mac', 'T'])
    diff = (gOUT['time'] - gIN['time']).to_frame()
    gIN['time_system'] = (diff['time'] / np.timedelta64(1, 's'))
    gIN = gIN[~gIN['time_system'].isin([0.0])]

    #       PLOT DISTRIBUTION  ########
    fig, axes = plt.subplots(nrows=2, ncols=1)
    axes[0].set_xlim(xmin=0, xmax=2000)
    axes[1].set_xlim(xmin=0, xmax=2000)
    gIN.plot(y='time_system', x=gIN['mac'],
             kind='hist', rot=0, ax=axes[0], legend=False)
    gIN.plot(y='time_system', kind='kde', ax=axes[1], legend=False)
    plt.savefig("img/time_in_system.jpg", bbox_inches="tight")

    if show is True:
        plt.show()
    plt.gcf().clear()


# ### Example
#
# Main program example with results

# In[17]:


df = consult_api()
# df = read_csv('Captura_Peritos.csv')


# In[18]:

mac_activty_good(df, False)


# In[19]:

mac_activity_bad(df, False)


# In[20]:

origin_activity(df, False)


# In[21]:

mac_occurs(df, False)


# In[22]:

mac_system(df, False)


# In[23]:

T_burst(df, False)

T_system(df, False)
