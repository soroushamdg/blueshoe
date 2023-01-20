from cProfile import label
from cmath import sqrt
from re import X
from unicodedata import name
import pandas as pd
import matplotlib.pyplot as plt
import plotly.express as px
import math

df = pd.read_csv('x_z_steady.csv')
x_data = df['data 0'].tolist()
y_data = df['data 1'].tolist()
z_data = df['data 2'].tolist()


fig = px.line(df, x='Program Time [s]', y = 'data 0' ,title='X,Y and Z plot')
fig.add_scatter(x=df['Program Time [s]'], y=df['data 0'], name='X')
fig.add_scatter(x=df['Program Time [s]'], y=df['data 2'], name='Z')

fig.show()