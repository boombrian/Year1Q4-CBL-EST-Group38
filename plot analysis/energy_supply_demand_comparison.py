import pandas as pd
import seaborn as sns
import matplotlib.pyplot as plt

# 1. Apply academic style using Seaborn
sns.set_theme(style="ticks", context="paper", font_scale=1.2)

# 2. Load the datasets
df_supply = pd.read_csv("Team38_supply.csv", skipinitialspace=True)
df_demand = pd.read_csv("Team38_demand.csv", skipinitialspace=True)

df_supply.columns = df_supply.columns.str.strip()
df_demand.columns = df_demand.columns.str.strip()

# 3. Group by discrete Days (matches the previous detailed daily representation spanning 365 Days)
df_supply['Time (Days)'] = (df_supply['time [s]'] // 86400).astype(int)
df_demand['Time (Days)'] = (df_demand['time [s]'] // 86400).astype(int)

# This preserves the full year density (365 exact daily points with Max backgrounds!)
supply_agg = df_supply.groupby('Time (Days)', observed=False)['power [MW]'].agg(Mean='mean', Max='max').reset_index()
demand_agg = df_demand.groupby('Time (Days)', observed=False)['power [MW]'].agg(Mean='mean', Max='max').reset_index()

# Extract merged frames
supply_agg['Type'] = 'Supply'
demand_agg['Type'] = 'Demand'
merged_agg = pd.concat([supply_agg, demand_agg], ignore_index=True)

# 4. Generate the Subplots
fig, axes = plt.subplots(3, 1, figsize=(10, 16), sharex=True)

# Subplot 1: Supply explicitly with 0 linewidth to prevent border crush on 365 bars
sns.barplot(data=supply_agg, x='Time (Days)', y='Max', color='lightgray', alpha=0.7, linewidth=0, ax=axes[0])
sns.lineplot(data=supply_agg, x='Time (Days)', y='Mean', color='darkblue', legend=False, errorbar=None, ax=axes[0])
axes[0].set_title('Supply: Wind park in Luxemburg with 140 turbines.', weight='bold')
axes[0].set_ylabel('Power [MW]')
axes[0].legend(handles=[
    plt.Rectangle((0,0),1,1, color='lightgray', alpha=0.7),
    plt.Line2D([], [], color='darkblue')
], labels=['Max Supply', 'Average Supply'])

# Subplot 2: Demand
sns.barplot(data=demand_agg, x='Time (Days)', y='Max', color='lightgray', alpha=0.7, linewidth=0, ax=axes[1])
sns.lineplot(data=demand_agg, x='Time (Days)', y='Mean', color='darkred', legend=False, errorbar=None, ax=axes[1])
axes[1].set_title('Demand: Public transport provider in Luxemburg with an annual energy consumption of 7.57e+14 J.', weight='bold')
axes[1].set_ylabel('Power [MW]')
axes[1].legend(handles=[
    plt.Rectangle((0,0),1,1, color='lightgray', alpha=0.7),
    plt.Line2D([], [], color='darkred')
], labels=['Max Demand', 'Average Demand'])

# Subplot 3: Merged Panel
sns.barplot(data=merged_agg, x='Time (Days)', y='Max', hue='Type', palette={'Supply': 'lightblue', 'Demand': 'lightcoral'}, alpha=0.7, linewidth=0, ax=axes[2])
sns.lineplot(data=merged_agg, x='Time (Days)', y='Mean', hue='Type', palette={'Supply': 'darkblue', 'Demand': 'darkred'}, legend=False, errorbar=None, ax=axes[2])
axes[2].set_title('Merged: Comparison of demand and supply', weight='bold')
axes[2].set_xlabel('Months')  # Set explicitly
axes[2].set_ylabel('Power [MW]')
axes[2].legend(handles=[
    plt.Rectangle((0,0),1,1, color='lightblue', alpha=0.7),
    plt.Rectangle((0,0),1,1, color='lightcoral', alpha=0.7),
    plt.Line2D([], [], color='darkblue'),
    plt.Line2D([], [], color='darkred')
], labels=['Max Supply', 'Max Demand', 'Average Supply', 'Average Demand'])

# Format x-axis accurately to display 'Month' labels directly over the raw 365 Days
month_starts = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334]
month_names = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
for ax in axes:
    ax.set_xticks(month_starts)
    ax.set_xticklabels(month_names)

sns.despine(fig)
plt.tight_layout()
plt.show()