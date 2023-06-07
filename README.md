# Inventory Management System

This is an inventory management system implemented using SQL Server. It allows you to manage suppliers, products, stocks, customers, orders, and purchase orders.

## Table of Contents

- [Features](#features)
- [Database Schema](#database-schema)

## Features

- Create, update, and delete suppliers
- Create, update, and delete products
- Track stock levels and set reorder levels
- Manage customer information
- Place orders for products and update stock levels simultaneously
- Update purchase order based on stock level

## Database Schema

The system uses a database with the following tables:

- `SUPPLIER`: Stores supplier information
- `PRODUCT`: Stores product information, with references to suppliers
- `STOCK`: Tracks stock levels and reorder levels for products
- `CUSTOMER`: Stores customer information
- `ORDERS`: Manages customer orders, with references to products and customers
- `PURCHASE`: Tracks purchases to be made, with references to stock
