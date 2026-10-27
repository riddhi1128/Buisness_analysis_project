Retail Sales Analytics - Exploratory Data Analysis
Setup: python -m pip install pandas matplotlib seaborn
Run from project root: python python/eda.py
The script uses the cleaned reference CSV included in data/. If you clean data in PostgreSQL, export clean_retail_sales to this same path/name.

from google.colab import files
uploaded = files.upload()

import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns

df = pd.read_csv('/content/raw_retail_sales.csv')

# 1. Quick overview
print("Rows and columns:", df.shape)

print("\nMissing values:\n", df.isna().sum().sort_values(ascending=False))

print("\nSummary statistics:\n",
      df[["quantity", "unit_price", "discount_pct"]].describe().round(2))

print("\nOrder statuses:\n", df["order_status"].value_counts())

# Convert order_date to datetime
df["order_date"] = pd.to_datetime(df["order_date"])

# Handle missing discounts
df["discount_pct"] = df["discount_pct"].fillna(0)

# Create net_sales
df["net_sales"] = (
    df["quantity"] * df["unit_price"] * (1 - df["discount_pct"])
)

# Create order_month
df["order_month"] = df["order_date"].dt.to_period("M").astype(str)
print(df[["order_date", "net_sales", "order_month"]].head())

from pathlib import Path

OUT_DIR = Path("/content/outputs")
OUT_DIR.mkdir(parents=True, exist_ok=True)

# 2. Monthly net sales trend
monthly = df.groupby("order_month", as_index=False)["net_sales"].sum()
plt.figure(figsize=(12, 5))
sns.lineplot(data=monthly, x="order_month", y="net_sales", marker="o")
plt.title("Monthly Net Sales Trend")
plt.xlabel("Month")
plt.ylabel("Net sales")
plt.xticks(rotation=60)
plt.tight_layout()
plt.savefig(OUT_DIR / "01_monthly_net_sales.png", dpi=150)
plt.show()
plt.close()

# 3. Net sales by product category
category_sales = df.groupby("category", as_index=False)["net_sales"].sum().sort_values("net_sales", ascending=False)
plt.figure(figsize=(9, 5))
sns.barplot(data=category_sales, x="net_sales", y="category")
plt.title("Net Sales by Category")
plt.xlabel("Net sales")
plt.ylabel("Category")
plt.tight_layout()
plt.savefig(OUT_DIR / "02_sales_by_category.png", dpi=150)
plt.close()


# 4. Top 10 products by net sales
top_products = df.groupby("product_name", as_index=False)["net_sales"].sum().nlargest(10, "net_sales")
plt.figure(figsize=(10, 6))
sns.barplot(data=top_products, x="net_sales", y="product_name")
plt.title("Top 10 Products by Net Sales")
plt.xlabel("Net sales")
plt.ylabel("Product")
plt.tight_layout()
plt.savefig(OUT_DIR / "03_top_products.png", dpi=150)
plt.close()

# 5. Sales channel comparison
channel_sales = df.groupby("sales_channel", as_index=False)["net_sales"].sum().sort_values("net_sales", ascending=False)
plt.figure(figsize=(8, 5))
sns.barplot(data=channel_sales, x="sales_channel", y="net_sales")
plt.title("Net Sales by Sales Channel")
plt.xlabel("Channel")
plt.ylabel("Net sales")
plt.xticks(rotation=20)
plt.tight_layout()
plt.savefig(OUT_DIR / "04_sales_by_channel.png", dpi=150)
plt.close()

# 6. Order status mix
status_counts = df["order_status"].value_counts().rename_axis("order_status").reset_index(name="orders")
plt.figure(figsize=(7, 5))
plt.pie(status_counts["orders"], labels=status_counts["order_status"], autopct="%1.1f%%", startangle=90)
plt.title("Order Status Mix")
plt.tight_layout()
plt.savefig(OUT_DIR / "05_order_status_mix.png", dpi=150)
plt.close()

# 7. Quantity vs net sales relationship
plt.figure(figsize=(8, 5))
sns.scatterplot(data=df, x="quantity", y="net_sales", hue="category", alpha=0.7)
plt.title("Quantity vs Net Sales")
plt.xlabel("Quantity")
plt.ylabel("Net sales")
plt.tight_layout()
plt.savefig(OUT_DIR / "06_quantity_vs_sales.png", dpi=150)
plt.close()

# 8. Sales by city
city_sales = df.groupby("city", as_index=False)["net_sales"].sum().sort_values("net_sales", ascending=False)
plt.figure(figsize=(9, 5))
sns.barplot(data=city_sales, x="net_sales", y="city")
plt.title("Net Sales by City")
plt.xlabel("Net sales")
plt.ylabel("City")
plt.tight_layout()
plt.savefig(OUT_DIR / "07_sales_by_city.png", dpi=150)
plt.close()

print(f"\\nDone! Charts saved in: {OUT_DIR}")
print("\\nSuggested questions to investigate:")
print("- Which months have the highest net sales?")
print("- Which category and product contribute the most revenue?")
print("- Which sales channel contributes the most net sales?")
print("- What share of orders are returned or cancelled?")
print("- Which cities contribute most to net sales?")
