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

# 3. Group by discrete Days for the top overall comparison plot
df_supply['Time (Days)'] = (df_supply['time [s]'] // 86400).astype(int)
df_demand['Time (Days)'] = (df_demand['time [s]'] // 86400).astype(int)

supply_agg = df_supply.groupby('Time (Days)', observed=False)['power [MW]'].agg(Mean='mean', Max='max').reset_index()
demand_agg = df_demand.groupby('Time (Days)', observed=False)['power [MW]'].agg(Mean='mean', Max='max').reset_index()

supply_agg['Type'] = 'Supply'
demand_agg['Type'] = 'Demand'
merged_agg = pd.concat([supply_agg, demand_agg], ignore_index=True)

month_starts = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334]
month_names = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']

def create_half_year_figure(month_indices, fig_title):
    fig = plt.figure(figsize=(18, 18))
    gs = fig.add_gridspec(4, 2)
    
    # --- Top Subplot: Full Year Comparison ---
    ax_top = fig.add_subplot(gs[0, :])
    
    sns.barplot(data=merged_agg, x='Time (Days)', y='Max', hue='Type', palette={'Supply': 'lightblue', 'Demand': 'lightcoral'}, alpha=0.7, linewidth=0, ax=ax_top)
    sns.lineplot(data=merged_agg, x='Time (Days)', y='Mean', hue='Type', palette={'Supply': 'darkblue', 'Demand': 'darkred'}, legend=False, errorbar=None, ax=ax_top)
    
    ax_top.set_title('Merged: Comparison of demand and supply (Full Year)', weight='bold')
    ax_top.set_xlabel('Months')
    ax_top.set_ylabel('Power [MW]')
    ax_top.legend(handles=[
        plt.Rectangle((0,0),1,1, color='lightblue', alpha=0.7),
        plt.Rectangle((0,0),1,1, color='lightcoral', alpha=0.7),
        plt.Line2D([], [], color='darkblue'),
        plt.Line2D([], [], color='darkred')
    ], labels=['Max Supply', 'Max Demand', 'Average Supply', 'Average Demand'], loc='upper right')
    
    ax_top.set_xticks(month_starts)
    ax_top.set_xticklabels(month_names)

    # --- Small Subplots: First Week of Each Month ---
    for i, m_idx in enumerate(month_indices):
        row = (i // 2) + 1
        col = i % 2
        ax = fig.add_subplot(gs[row, col])
        
        start_day = month_starts[m_idx]
        end_day = start_day + 6
        
        # Extract 1st week data for current month
        week_supply = df_supply[(df_supply['Time (Days)'] >= start_day) & (df_supply['Time (Days)'] <= end_day)]
        week_demand = df_demand[(df_demand['Time (Days)'] >= start_day) & (df_demand['Time (Days)'] <= end_day)]
        
        # Time in days (relative to day 1 to 7 of that month)
        x_supply = (week_supply['time [s]'] - start_day * 86400) / 86400.0 + 1
        x_demand = (week_demand['time [s]'] - start_day * 86400) / 86400.0 + 1
        
        # Background bars using light colors
        ax.bar(x_supply, week_supply['power [MW]'], width=0.01, color='lightblue', alpha=0.7, linewidth=0)
        ax.bar(x_demand, week_demand['power [MW]'], width=0.01, color='lightcoral', alpha=0.7, linewidth=0)
        
        # Foreground lines using exact data (no averages)
        ax.plot(x_supply, week_supply['power [MW]'], color='darkblue', linewidth=1)
        ax.plot(x_demand, week_demand['power [MW]'], color='darkred', linewidth=1)
        
        ax.set_title(f'{month_names[m_idx]} - First Week', weight='bold')
        if i >= 4:
            ax.set_xlabel('Day of Month')
        ax.set_ylabel('Power [MW]')
        
        if i == 0:
            ax.legend(handles=[
                plt.Rectangle((0,0),1,1, color='lightblue', alpha=0.7),
                plt.Rectangle((0,0),1,1, color='lightcoral', alpha=0.7),
                plt.Line2D([], [], color='darkblue'),
                plt.Line2D([], [], color='darkred')
            ], labels=['Supply (Bar)', 'Demand (Bar)', 'Supply (Line)', 'Demand (Line)'], loc='upper right')
            
    fig.suptitle(fig_title, weight='bold', fontsize=16)
    sns.despine(fig)
    plt.tight_layout(rect=[0, 0, 1, 0.96])
    plt.show()

# 4. Generate the two figures
create_half_year_figure([0, 1, 2, 3, 4, 5], "First Half Year (Jan-Jun)")
create_half_year_figure([6, 7, 8, 9, 10, 11], "Second Half Year (Jul-Dec)")
