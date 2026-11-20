# Slayd Ol ovozi - ElevenLabs. Kalit $env:ELEVENLABS_API_KEY dan olinadi.
$ErrorActionPreference = "Stop"
$key = $env:ELEVENLABS_API_KEY
if (-not $key) { Write-Host "ELEVENLABS_API_KEY topilmadi"; return }
$h = @{ "xi-api-key" = $key }
$dir = Join-Path $HOME "slaydol_wow"; New-Item -ItemType Directory -Force -Path $dir | Out-Null; Set-Location $dir
$voices = (Invoke-RestMethod -Uri "https://api.elevenlabs.io/v1/voices" -Headers $h).voices
for ($i = 0; $i -lt $voices.Count; $i++) { Write-Host ("{0,3}. {1}  [{2}]" -f ($i + 1), $voices[$i].name, $voices[$i].category) }
$n = [int](Read-Host "Qaysi ovoz? Raqamini yozing")
$voice = $voices[$n - 1].voice_id
Write-Host ("Tanlandi: " + $voices[$n - 1].name)
$segs = @(
  "Bu taqdimotlarning hammasini bot yasadi.",
  "Siz faqat mavzuni yozasiz.",
  "Rasmli, rejali, chiroyli taqdimot - PowerPoint va PDF'da.",
  "Telegramda Slayd Ol - hoziroq sinab ko'ring!"
)
function Say($text, $out, $model) {
  $body = @{ text = $text; model_id = $model; voice_settings = @{ stability = 0.45; similarity_boost = 0.8; style = 0.35; use_speaker_boost = $true } } | ConvertTo-Json -Depth 4
  $bytes = [Text.Encoding]::UTF8.GetBytes($body)
  Invoke-WebRequest -UseBasicParsing -Uri ("https://api.elevenlabs.io/v1/text-to-speech/" + $voice + "?output_format=mp3_44100_128") -Method Post -Headers $h -ContentType "application/json; charset=utf-8" -Body $bytes -OutFile $out | Out-Null
}
Remove-Item seg*.mp3 -ErrorAction SilentlyContinue
for ($i = 0; $i -lt $segs.Count; $i++) {
  $out = "seg$($i + 1).mp3"
  try { Say $segs[$i] $out "eleven_v3" }
  catch {
    Write-Host ("eleven_v3: " + $_.Exception.Message + " -> multilingual_v2 bilan urinaman")
    try { Say $segs[$i] $out "eleven_multilingual_v2" } catch { Write-Host ("XATO: " + $_.ErrorDetails.Message + " " + $_.Exception.Message); return }
  }
  Write-Host "Tayyor: $out"
}
Compress-Archive -Force seg*.mp3 (Join-Path $HOME "slaydol_wow.zip")
Write-Host "Hammasi tayyor! slaydol_wow.zip faylini Claude'ga yuboring."
explorer $HOME
