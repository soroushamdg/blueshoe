from cProfile import label
from cmath import sqrt
from re import X
import pandas as pd
import matplotlib.pyplot as plt
import plotly.express as px
import math

df = pd.read_csv('x_z_moving_2.csv')
x_data = df['data 0'].tolist()
z_data = df['data 2'].tolist()
df['data 4'] = [
    pow(x_data[i], 2) + pow(z_data[i], 2) for i in range(len(x_data))
]

fig = px.line(df, x='Program Time [s]', y='data 4', title='X and Z plot')
fig.add_scatter(x=df['Program Time [s]'], y=df['data 0'], name='X')
fig.add_scatter(x=df['Program Time [s]'], y=df['data 2'], name='Z')

fig.show()