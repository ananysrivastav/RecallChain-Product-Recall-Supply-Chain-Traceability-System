# RecallChain – Product Recall \& Supply Chain Traceability System

RecallChain is a supply-chain traceability project designed to help users track products and batches across the supply chain and manage product recalls when a defect is reported. It aims to connect product, supplier, batch, and shipment information in one relational database so that potentially affected products can be identified more efficiently.

> \*\*Project status:\*\* In development. The initial MySQL database design, table relationships, and sample records have been prepared. Frontend, backend integration, product tracing, recall management, and OS-related background processing are planned next stages.

## Problem Statement

When a product is found to be defective, identifying the affected batches and determining where products have been sent can take time—especially when supplier, production, warehouse, and shipment information is disconnected.

RecallChain aims to organize related supply-chain records in one application, making it easier to trace products, identify affected batches, and maintain recall records.

## Objectives

* Store related supply-chain information in a structured relational database.
* Trace products and batches using available records.
* Create and track product recall records.
* Connect a web interface to a backend API and MySQL database.
* Explore operating-system concepts through background jobs and concurrent processing.

## Planned Features

* **Supply-chain records:** Maintain information about products, suppliers, batches, and shipments.
* **Product and batch tracing:** Follow stored records to help identify potentially affected products.
* **Recall management:** Create recall records and track their status.
* **Database operations:** Store and retrieve connected records using MySQL and SQL queries.
* **Background processing:** Add selected recall-related jobs and notifications as part of the OS component.
* **Audit logs and reports:** Planned support for reviewing system activity and generating reports.
* **Testing and documentation:** Validate the application using sample supply-chain data.

*The features above are planned deliverables unless explicitly identified as completed in the project status.*

## Technology Stack

|Component|Technology|Purpose|
|-|-|-|
|Frontend|React.js|User interface|
|Backend|Node.js, Express.js|REST API and application logic|
|Database|MySQL|Relational storage for supply-chain records|
|OS concepts|Background workers and job scheduling (planned)|Explore background processing and concurrency|

## High-Level Architecture

```text
User
  |
  v
React.js Frontend
  |
  | HTTP / REST
  v
Node.js + Express.js Backend
  |                     \\
  | SQL Queries          \\ Planned job manager
  v                       v
MySQL Database        Background Workers
  |
  v
Supply-chain Records, Recall Data
and (planned) Audit Logs / Reports
```

The frontend will send requests to the backend API. The backend will validate and process requests and use SQL queries to read or update data in MySQL. Background workers and job scheduling are planned for selected recall-related tasks.

## Current Progress

### Completed

* Initial database structure designed.
* Required tables created.
* Relationships between tables defined.
* Sample records inserted.
* Basic SQL insert and retrieval operations tested.

### Planned

* Recheck and refine database relationships as development continues.
* Build the backend using Node.js and Express.js.
* Connect the backend to MySQL.
* Develop the React.js frontend.
* Implement product/batch tracing and recall-status management.
* Add selected background jobs for the Operating Systems component.
* Test the integrated application and document the results.

## Database Scope

The database is intended to hold related information about:

* Products
* Suppliers
* Batches
* Shipments
* Recall records and related status information

The final schema may change as implementation and testing progress.

## Getting Started

The complete application setup instructions will be added once the frontend and backend are integrated. At the current stage, the database schema and sample data are the primary implemented components.

### Prerequisites (planned application stack)

* MySQL
* Node.js and npm
* A React-compatible development environment

### Setup (to be completed)

1. Clone this repository.
2. Import the project's SQL schema and sample data into MySQL.
3. Configure the backend database connection using local environment variables.
4. Install backend and frontend dependencies.
5. Start the backend and frontend development servers.

> \*\*Note:\*\* Exact commands, environment-variable names, and SQL import instructions should be added after the corresponding files and scripts are committed to the repository. Do not commit database passwords or other secrets.

## Assumptions and Limitations

* The project currently uses sample data.
* Users are assumed to provide correct product, supplier, batch, and shipment information.
* RecallChain does not independently detect product defects. A defect must first be reported or identified through a quality check.
* Traceability results depend on the accuracy and completeness of the stored records.

## Team

**Team Name:** TraceX

* Anany Kumar Srivastav — Team Lead
* Tanisha Rawat
* Dhruv Gupta
* Kavya

## References

* [React Documentation](https://react.dev/)
* [Node.js Documentation](https://nodejs.org/docs/latest/api/)
* [Express.js Documentation](https://expressjs.com/)
* [MySQL Documentation](https://dev.mysql.com/doc/)
* Silberschatz, A., Galvin, P. B., \& Gagne, G. *Operating System Concepts*. Wiley.
* Elmasri, R. \& Navathe, S. B. *Fundamentals of Database Systems*. Pearson.



*RecallChain is an academic project developed as part of the OS and DBMS coursework.*

