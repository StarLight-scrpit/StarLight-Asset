local CountryData = {}

local nativeCountries = {
	["AL"] = "Shqipëria", ["DZ"] = "الجزائر", ["AD"] = "Andorra", ["AO"] = "Angola", ["AG"] = "Antigua & Barbuda",
	["AR"] = "Argentina", ["AM"] = "Հայաստան", ["AW"] = "Aruba", ["AU"] = "Australia", ["AT"] = "Österreich",
	["AZ"] = "Azərbaycan", ["BS"] = "Bahamas", ["BH"] = "البحرين", ["BD"] = "বাংলাদেশ", ["BB"] = "Barbados",
	["BY"] = "Belarussiya", ["BE"] = "België", ["BZ"] = "Belize", ["BJ"] = "Bénin", ["BM"] = "Bermuda",
	["BT"] = "འབྲུག་ཡུལ", ["BO"] = "Bolivia", ["BA"] = "Bosna I Hercegovina", ["BW"] = "Botswana", ["BR"] = "Brasil",

	["BN"] = "Brunei", ["BG"] = "България", ["BF"] = "Burkina Faso", ["BI"] = "Uburundi", ["KH"] = "កម្ពុជា",
	["CM"] = "Cameroun", ["CA"] = "Canada", ["CV"] = "Cabo Verde", ["KY"] = "Cayman Islands", ["CL"] = "Chile",
	["CN"] = "中国", ["CO"] = "Colombia", ["KM"] = "Komori", ["CG"] = "Congo", ["CD"] = "Congo (Rdc)",
	["CR"] = "Costa Rica", ["CI"] = "Côte D'Ivoire", ["HR"] = "Hrvatska", ["CW"] = "Curaçao", ["CY"] = "Kýpros",
	["CZ"] = "Česká Republika", ["DK"] = "Danmark", ["DJ"] = "Djibouti", ["DM"] = "Dominica", ["DO"] = "República Dominicana",

	["EC"] = "Ecuador", ["EG"] = "مصر", ["SV"] = "El Salvador", ["EE"] = "Eesti", ["SZ"] = "Eswatini",
	["ET"] = "Ityop'Iya", ["FJ"] = "Viti", ["FI"] = "Suomi", ["FR"] = "France", ["GA"] = "Gabon",
	["GM"] = "Gambia", ["GE"] = "ساقارطویلو", ["DE"] = "Deutschland", ["GH"] = "Ghana", ["GI"] = "Gibraltar",
	["GR"] = "Ελλάδα", ["GL"] = "Kalaallit Nunaat", ["GD"] = "Grenada", ["GP"] = "Guadeloupe", ["GU"] = "Guam",
	["GT"] = "Guatemala", ["GN"] = "Guinée", ["GY"] = "Guyana", ["HT"] = "Haïti", ["HN"] = "Honduras",

	["HK"] = "香港", ["HU"] = "Magyarország", ["IS"] = "Ísland", ["IN"] = "भारत", ["ID"] = "Indonesia",
	["IQ"] = "العراق", ["IE"] = "Éire", ["IL"] = "ישראל", ["IT"] = "Italia", ["JM"] = "Jamaica",
	["JP"] = "日本", ["JO"] = "الأردن", ["KZ"] = "Qazaqstan", ["KE"] = "Kenya", ["KR"] = "대한민국",
	["KW"] = "الكويت", ["KG"] = "Kyrgyzstan", ["LA"] = "ລາວ", ["LV"] = "Latvija", ["LB"] = "لبنان",
	["LS"] = "Lesotho", ["LR"] = "Liberia", ["LY"] = "ليبيا", ["LI"] = "Liechtenstein", ["LT"] = "Lietuva",

	["LU"] = "Lëtzebuerg", ["MO"] = "澳門", ["MG"] = "Madagasikara", ["MW"] = "Malawi", ["MY"] = "Malaysia",
	["MV"] = "Dhivehi Raajje", ["ML"] = "Mali", ["MT"] = "Malta", ["MR"] = "Mūritāniyā", ["MU"] = "Maurice",
	["MX"] = "México", ["FM"] = "Micronesia", ["MD"] = "Moldova", ["MC"] = "Monaco", ["MN"] = "Монгол Uls",
	["ME"] = "Crna Gora", ["MA"] = "المغرب", ["MZ"] = "Moçambique", ["MM"] = "Myanma", ["NA"] = "Namibia",
	["NP"] = "नेपाल", ["NL"] = "Nederland", ["NZ"] = "Aotearoa", ["NI"] = "Nicaragua", ["NE"] = "Niger",

	["NG"] = "Nigeria", ["MK"] = "Severna Makedonija", ["NO"] = "Norge", ["OM"] = "عُمان", ["PK"] = "پاکستان",
	["PW"] = "Belau", ["PS"] = "فلسطين", ["PA"] = "Panamá", ["PG"] = "Papua Niugini", ["PY"] = "Paraguay",
	["PE"] = "Perú", ["PH"] = "Pilipinas", ["PL"] = "Polska", ["PT"] = "Portugal", ["PR"] = "Puerto Rico",
	["QA"] = "قطر", ["RO"] = "România", ["RU"] = "Россия", ["RW"] = "Uruwanda", ["KN"] = "Saint Kitts & Nevis",
	["LC"] = "Saint Lucia", ["VC"] = "St. Vincent & Grenadines", ["WS"] = "Sāmoa", ["SM"] = "San Marino", ["SA"] = "العربية السعودية",

	["SN"] = "Sénégal", ["RS"] = "Srbija", ["SC"] = "Sesel", ["SL"] = "Sierra Leone", ["SG"] = "Singapore",
	["SK"] = "Slovensko", ["SI"] = "Slovenija", ["SB"] = "Solomon Islands", ["SO"] = "Soomaaliya", ["ZA"] = "South Africa",
	["ES"] = "España", ["LK"] = "Śrī Laṅkā", ["SD"] = "السودان", ["SR"] = "Suriname", ["SE"] = "Sverige",
	["CH"] = "Schweiz", ["TW"] = "台灣", ["TJ"] = "Tojikiston", ["TZ"] = "Tanzania", ["TH"] = "ประเทศไทย",
	["TL"] = "Timor-Leste", ["TG"] = "Togo", ["TO"] = "Tonga", ["TT"] = "Trinidad & Tobago", ["TN"] = "Tūnis",

	["TR"] = "Türkiye", ["TM"] = "Türkmenistan", ["UG"] = "Uganda", ["UA"] = "Україна", ["AE"] = "الإمارات",
	["GB"] = "United Kingdom", ["US"] = "United States", ["UY"] = "Uruguay", ["UZ"] = "Oʻzbekiston", ["VU"] = "Vanuatu",
	["VE"] = "Venezuela", ["VN"] = "Việt Nam", ["YE"] = "اليمن", ["ZM"] = "Zambia", ["ZW"] = "Zimbabwe",
	["N/A"] = "Unknown"
}

local countryToCode = {}
local counter = {
	code = {},
	name = {}
}

for code, name in pairs(nativeCountries) do
	countryToCode[string.lower(name)] = code
	table.insert(counter.code, code)
end

table.sort(counter.code)

for _, code in ipairs(counter.code) do
	table.insert(counter.name, nativeCountries[code])
end

function CountryData.getName(code: string): string
	return (code and code ~= "") and (nativeCountries[string.upper(code)] or code) or "Unknown"
end

function CountryData.getCode(countryName: string): string
	return (countryName and countryName ~= "") and (countryToCode[string.lower(countryName)] or "N/A") or "N/A"
end

function CountryData.showCode() return counter.code end
function CountryData.showName() return counter.name end

return CountryData
