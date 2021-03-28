# Wymaganie do uruchomienia tego skryptu jest:
# - windows z powershellem w wersji co najmniej 5.0
# - zainstalowany azure cli
# - wykonana komenda: az login
# - wykonana komenda: az account set --subscription "NAZWA_SUBSKRYPCJI"

Param(
    [Parameter(Mandatory = $false)]
    [String]
    $AppName="rssfeed-app"
)

Write-Output "Nazwa aplikacji: $AppName."

# stworzenie resource group'y
Write-Output "Tworzenie resource group'y..."
$ResourceGroupName = "rg-$AppName"
$ResourceLocation = "westeurope"
az group create -l $ResourceLocation -n $ResourceGroupName
Write-Output "Utworzono resource group'e."

# stworzenie postgress
Write-Output "Tworzenie PostgreSQL..."
$PostgressName = "psql-$AppName"
$PostgressUserName = "RssFeedAdmin"
$PostgreSQLPassword = "5RgxALhz"
$DbName = "postgres"
az postgres server create --resource-group $ResourceGroupName --name $PostgressName --location $ResourceLocation --admin-user $PostgressUserName --admin-password $PostgreSQLPassword --sku-name B_Gen5_1 --auto-grow Disabled --storage-size 5120
Write-Output "Utworzono PostgreSQL"

# włączenie dostępu do PostgreSQL dla usług Azure
az postgres server firewall-rule create -g $ResourceGroupName -s $PostgressName -n "AllowAllWindowsAzureIps" --start-ip-address "0.0.0.0" --end-ip-address "0.0.0.0"

# stworzenie app service plan
Write-Output "Tworzenie service plan'u..."
$AppServicePlanName = "asp-$AppName"
az appservice plan create -g $ResourceGroupName -n $AppServicePlanName --is-linux --number-of-workers 1 --sku B1
Write-Output "Utworzono service plan."

# stworzenie app service
Write-Output "Tworzenie app service'u..."
$AppServiceName = "as-$AppName"
az webapp create -g $ResourceGroupName -p $AppServicePlanName -n $AppServiceName --runtime '"PYTHON|3.7"'
Write-Output "Utworzono app service."

# Dodanie zmiennych środowiskowych ze szczegółami o bazie danych do app service, jest to dobra praktyka aby nie hardcodować haseł do bazy w kodzie
# tylko jako zmienne środowiskowe które aplikacja czyta ze środowiska w którym jest uruchomiona
Write-Output "Dodawania zmiennych srodowiskowych do app service..."
## zmienna odpowiadająca za zainstalowanie modułów z pliku requirements.txt
az webapp config appsettings set -g $ResourceGroupName -n $AppServiceName --settings SCM_DO_BUILD_DURING_DEPLOYMENT=true
## zmienna odpowiadająca za uruchomienie dodatkowego skryptu zanim zostanie uruchomiana aplikacja aby wykonać migrację na bazie danych
az webapp config appsettings set -g $ResourceGroupName -n $AppServiceName --settings POST_BUILD_COMMAND="python manage.py migrate"
## nazwa bazy danych
az webapp config appsettings set -g $ResourceGroupName -n $AppServiceName --settings DB_NAME=$DbName
## user bazy danych
az webapp config appsettings set -g $ResourceGroupName -n $AppServiceName --settings DB_USERNAME="$PostgressUserName@$PostgressName"
## hasło bazy danych
az webapp config appsettings set -g $ResourceGroupName -n $AppServiceName --settings DB_PASSWORD=$PostgreSQLPassword
## host bazy danych
az webapp config appsettings set -g $ResourceGroupName -n $AppServiceName --settings DB_HOST="$PostgressName.postgres.database.azure.com"
## port bazy danych
az webapp config appsettings set -g $ResourceGroupName -n $AppServiceName --settings DB_PORT=5432
Write-Output "Dodano zmienne srodowiskowe."

# wdrożenie aplikacji
Write-Output "Wdrazanie aplikacji..."
az webapp up --name $AppServiceName --resource-group $ResourceGroupName --plan $AppServicePlanName --location $ResourceLocation
Write-Output "Pomyslnie wdrozono aplikacje. W czasie do okolo 15 minut moze pojawiac sie blad 404 ze wzgledu na konfigurowanie sie aplikacji po wdrozeniu (migracja bazy danych itd). Po tym czasie strona powinna byc juz prawidlowo dostepna pod adresem https://$AppServiceName.azurewebsites.net."