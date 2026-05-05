-- This information tells other players more about the mod
name = "Favorite Items"
description = [[
[NOW CLIENT-SIDE!] - Works on any server.
Favorite your items in inventory, always remain in the chosen slot.

- Hold Shift + Middle Click on an item to favorite it.
- Doing it again will remove or move the favorite to the current slot.
- Press CTRL + SHIFT + Z to reset all favorited items.
- Crash protection added.

[AGORA CLIENT-SIDE!] - Funciona em qualquer servidor.
Favorita seus itens no inventario para que sempre retornem ao slot escolhido.

- Segure Shift + Clique do Meio em um item para favoritar.
- Repetir o processo remove ou move o favorito para o slot atual.
- Pressione CTRL + SHIFT + Z para resetar todos os itens favoritados.
- Proteção contra crashes adicionada.

Available in: English, Portuguese, Chinese, Russian, and Spanish.
]]

author = "ZeroHora"
version = "1.2.3"

icon_atlas = "modicon.xml"
icon = "modicon.tex"

forumthread = ""

-- This lets other players know if your mod is out of date, update it to match the current version in the game
api_version_dst = 10

priority = 100

-- Only compatible with DST
dont_starve_compatible = false
reign_of_giants_compatible = false
shipwrecked_compatible = false
dst_compatible = true


--This lets clients know if they need to get the mod from the Steam Workshop to join the game
all_clients_require_mod = false

--This determines whether it causes a server to be marked as modded (and shows in the mod list)
client_only_mod = true

--These tags allow the server running this mod to be found with filters from the server listing screen
server_filter_tags = {""}

configuration_options = 
{
    {
        name = "LANGUAGE",
        label = "Language / Idioma",
        hover = "Choose the mod language / Escolha o idioma do mod.",
        options =
        {
            {description = "English", data = "en"},
            {description = "Português", data = "pt"},
            {description = "Chinese", data = "zh"},
            {description = "Russian", data = "ru"},
            {description = "Spanish", data = "es"},
        },
        default = "en",
    },
}