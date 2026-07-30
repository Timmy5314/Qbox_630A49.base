# renzu_vehicleshop
FIVEM VEHICLE SHOP HUD (WIP) v1 to v2 progress
Stable version here - > https://github.com/renzuzu/renzu_vehicleshop/releases/tag/v1final

# Current Feature
- Multi Shops
- Job Vehicle Shop
- Multi Payment Method
- Categorized Shop
- Users Able to Sell Owned Vehicles
- Clean UI
- Test Driving

# Vehicle Shop
![image](https://user-images.githubusercontent.com/82306584/134146299-98acde76-96db-4e37-b13e-0d5a5c885867.png)
![image](https://user-images.githubusercontent.com/82306584/133435463-76be5e05-306b-4634-847b-e8b2c5b7c367.png)

# Display Cars
![image](https://user-images.githubusercontent.com/82306584/130480955-d65b000d-7955-4705-85c9-fb680e115638.png)

# todo
- PDM Management -- Progressing
- Multi Shop
- Stock Management
- Odd jobs possible
- Change Colors Before Purchasing
- Support Different Payments
- Reposes Job?

# Dependency
- Qbox (qbx_core) - https://github.com/Qbox-project/qbx_core
- ox_lib
- oxmysql
- ox_target (aanbevolen: ped-interactie; zonder ox_target valt het terug op press-E marker)

# Installatie
- Importeer `qbcore.sql` in je database (dit schema geldt ook voor Qbox, want Qbox behoudt de `player_vehicles`-tabelstructuur).
- Zorg dat de mapnaam exact `renzu_vehicleshop` is.
- Startvolgorde in server.cfg:
```
ensure qbx_core
ensure ox_lib
ensure oxmysql
ensure ox_target
ensure renzu_vehicleshop
```

# DEMO
https://www.youtube.com/watch?v=F4HldNMwvr0
