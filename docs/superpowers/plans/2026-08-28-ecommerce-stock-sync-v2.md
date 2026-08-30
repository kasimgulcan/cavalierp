# E-ticaret stok senkronu v2 — Implementation Plan

> **For agentic workers:** Implement task-by-task. TDD for C# units. SQL is applied on the server via `sql/EcommerceStockWebhook.sql`.

**Goal:** Site snapshot çeker; satış/iade delta inbound; CavaliERP satış/stok insert-update-delete outbound webhook (outbox + trigger).

**Architecture:** Inbound SP writes Sales/StockEntries with `Note=ecommerce`. Triggers enqueue `StockWebhookOutbound` except ecommerce notes. API worker HMAC-POSTs to `SubscriberUrl`.

**Tech Stack:** ASP.NET Core, SQL Server, web tester (`/tester/`), xUnit.

## Global Constraints

- Inbound `sale.created` / `return.created` only; v1 `stock.updated` rejected
- Quantity inbound ≥ 1; negative onHand allowed
- SizeId never in external JSON
- HMAC canonical unchanged
- Do not commit secrets

## Files

- `sql/EcommerceStockWebhook.sql` — tables, triggers, SPs
- `api/CavaliERP.API/Services/Ecommerce/*` — validate, repo, mapper, dispatcher, worker
- `api/CavaliERP.API/Models/EcommerceStockModels.cs`, `Controllers/EcommerceStockController.cs`, `Program.cs`, `appsettings*.json`
- `api/CavaliERP.API.TESTS/*`
- `api/CavaliERP.API/wwwroot/tester/`, `EcommerceTesterController`
- `docs/ecommerce-stock-webhook.md`, spec status
