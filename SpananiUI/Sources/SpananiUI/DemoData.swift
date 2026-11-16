import Foundation
import SwiftUI

public enum DemoData {
    @MainActor
    public static func makeModel() -> StoreModel {
        let apps: [StoreItem] = [
            StoreItem(
                id: "de.spanani.fmhy",
                name: "FMHY",
                subtitle: "Wiki & Link-Prüfer für freies Wissen",
                developer: "FreiSoftware Kollektiv",
                description: "Das umfassendste Verzeichnis nützlicher Werkzeuge, Bildungsressourcen und Medien im Netz. Mit integrierter Sicherheitsprüfung für externe Links und Offline-Lesezeichen. Schnelle Volltextsuche und kuratierte Empfehlungen.",
                category: "Werkzeuge",
                versionString: "1.6.0",
                sizeBytes: 19_400_000,
                sourceName: "spanani.de",
                tint: Color(red: 0.60, green: 0.33, blue: 0.91),
                symbol: "link.badge.plus",
                iconURL: nil,
                screenshotURLs: [],
                whatsNew: "Version 1.6.0 bringt einen verbesserten Link-Filter, Dunkelmodus-Optimierungen und schnellere Ladezeiten für Offline-Artikel.",
                permissions: ["Netzwerkzugriff", "Lokaler Speicher"],
                isFeatured: true,
                heroTagline: "Entwickler-Liebling"
            ),
            StoreItem(
                id: "de.spanani.kippe",
                name: "Kippe",
                subtitle: "Minimalistisches Physik- und Balance-Spiel",
                developer: "Studio Schieflage",
                description: "Halte die schwebende Plattform durch feinfühlige Neigung deines Geräts im Gleichgewicht. Physikbasierte Rätsel mit sanftem haptischem Feedback und beruhigendem Soundtrack. Jedes Level stellt deine Geschicklichkeit auf die Probe.",
                category: "Spiele",
                versionString: "1.0.4",
                sizeBytes: 42_800_000,
                sourceName: "spanani.de",
                tint: Color(red: 0.95, green: 0.45, blue: 0.25),
                symbol: "circle.grid.cross.fill",
                iconURL: nil,
                screenshotURLs: [],
                whatsNew: "10 neue Level, Unterstützung für erweiterte Haptik und feinere Gyroskop-Empfindlichkeit.",
                permissions: ["Bewegungssensoren"],
                isFeatured: true,
                heroTagline: "Neu im Store"
            ),
            StoreItem(
                id: "de.spanani.pausenklau",
                name: "Pausenklau",
                subtitle: "Kurzweilige Mini-Rätsel für Zwischendurch",
                developer: "Lukas Bergmann",
                description: "Kleine Denkspiele, die exakt drei Minuten dauern – perfekt für die Kaffeepause. Keine Werbung, keine In-App-Käufe, nur reiner Knobelspaß. Tägliche Herausforderungen mit deinen Freunden teilbar.",
                category: "Spiele",
                versionString: "2.3.1",
                sizeBytes: 15_200_000,
                sourceName: "spanani.de",
                tint: Color(red: 0.25, green: 0.75, blue: 0.85),
                symbol: "gamecontroller.fill",
                iconURL: nil,
                screenshotURLs: [],
                whatsNew: "Neue Kategorie für Zahlenrätsel und synchronisierte Highscores.",
                permissions: ["Lokaler Speicher"],
                isFeatured: false,
                heroTagline: ""
            ),
            StoreItem(
                id: "de.spanani.tagesspiele",
                name: "Tagesspiele",
                subtitle: "Wort- und Logikrätsel jeden Morgen neu",
                developer: "Rätselmanufaktur",
                description: "Jeden Tag ein neues handgefertigtes Kreuzwort- und Zahlenrätsel direkt auf dein Gerät geliefert. Trainiere dein Gedächtnis und deinen Wortschatz mit elegantem Design. Behalte deine Serie im Blick.",
                category: "Spiele",
                versionString: "1.4.0",
                sizeBytes: 28_100_000,
                sourceName: "spanani.de",
                tint: Color(red: 0.92, green: 0.70, blue: 0.20),
                symbol: "calendar.badge.clock",
                iconURL: nil,
                screenshotURLs: [],
                whatsNew: "Wochenend-Spezialrätsel mit doppelter Wortlänge hinzugefügt.",
                permissions: ["Mitteilungen"],
                isFeatured: false,
                heroTagline: ""
            ),
            StoreItem(
                id: "de.spanani.lyricshud",
                name: "Lyrics HUD",
                subtitle: "Synchronisierte Liedtexte über jeder Musik-App",
                developer: "Klangwerk",
                description: "Zeigt Liedtexte zeilengenau und synchron zu deiner Musik im schwebenden Fenster an. Unterstützt deine bevorzugten Streaming-Dienste und lokale Audio-Dateien. Gestalte Schriftart und Deckkraft nach deinen Wünschen.",
                category: "Medien",
                versionString: "3.0.2",
                sizeBytes: 24_600_000,
                sourceName: "spanani.de",
                tint: Color(red: 0.88, green: 0.28, blue: 0.55),
                symbol: "music.note.tv.fill",
                iconURL: nil,
                screenshotURLs: [],
                whatsNew: "Unterstützung für mehrsprachige Übersetzungen in Echtzeit.",
                permissions: ["Medienbibliothek", "Hintergrund-Audio"],
                isFeatured: true,
                heroTagline: "Jetzt aktualisiert"
            ),
            StoreItem(
                id: "de.spanani.strullermod",
                name: "Strullermod Companion",
                subtitle: "Echtzeit-Telemetrie und Spielstände verwalten",
                developer: "Modding Zentrale",
                description: "Verbinde dein Smartphone mit deinem lokalen Spieleserver für Live-Statistiken und Inventarverwaltung. Erhalte Benachrichtigungen bei Server-Events und verwalte Mods mit einem Fingertipp. Vollständige Ende-zu-Ende-Verschlüsselung.",
                category: "Werkzeuge",
                versionString: "0.9.8",
                sizeBytes: 31_500_000,
                sourceName: "spanani.de",
                tint: Color(red: 0.35, green: 0.80, blue: 0.45),
                symbol: "antenna.radiowaves.left.and.right",
                iconURL: nil,
                screenshotURLs: [],
                whatsNew: "Optimierte Server-Ping-Anzeige und automatische Verbindungswiederherstellung.",
                permissions: ["Netzwerkzugriff", "Lokales Netzwerk"],
                isFeatured: false,
                heroTagline: ""
            ),
            StoreItem(
                id: "de.spanani.kistensortierer",
                name: "Kisten-Sortierer",
                subtitle: "Haushaltsinventar mit Barcode-Scanner",
                developer: "Ordnungsliebe",
                description: "Organisiere Keller, Umzugskartons und Vorratskammern mühelos mit QR-Codes. Finde jeden Gegenstand in Sekundenschnelle per Volltextsuche und Foto-Erkennung. Exportiere Inventarlisten im handlichen PDF-Format.",
                category: "Werkzeuge",
                versionString: "2.0.1",
                sizeBytes: 21_700_000,
                sourceName: "spanani.de",
                tint: Color(red: 0.72, green: 0.48, blue: 0.34),
                symbol: "shippingbox.fill",
                iconURL: nil,
                screenshotURLs: [],
                whatsNew: "Stapel-Scan-Modus zum schnellen Erfassen ganzer Kisteninhalte.",
                permissions: ["Kamera", "Lokaler Speicher"],
                isFeatured: false,
                heroTagline: ""
            ),
            StoreItem(
                id: "de.spanani.lautstaerkebooster",
                name: "Lautstärke-Booster",
                subtitle: "Präziser Equalizer und Dynamik-Kompression",
                developer: "AudioDSP Labs",
                description: "Hole das Beste aus leisen Podcasts, älteren Aufnahmen und Videos heraus. Mit parametrischem 10-Band-Equalizer und Gehörschutz-Begrenzer. Speichere benutzerdefinierte Profile für Kopfhörer und Lautsprecher.",
                category: "Medien",
                versionString: "1.2.0",
                sizeBytes: 12_900_000,
                sourceName: "spanani.de",
                tint: Color(red: 0.95, green: 0.30, blue: 0.35),
                symbol: "speaker.wave.3.fill",
                iconURL: nil,
                screenshotURLs: [],
                whatsNew: "Neuer Sprachverstärkungs-Modus für besonders verständliche Stimmen.",
                permissions: ["Mikrofon", "Audioausgabe"],
                isFeatured: false,
                heroTagline: ""
            ),
            StoreItem(
                id: "de.spanani.wetterfrosch",
                name: "Wetterfrosch",
                subtitle: "Open-Source Wettervorhersage ohne Tracker",
                developer: "Freie Meteorologie",
                description: "Hochpräzise Vorhersagen direkt von europäischen Wetterdiensten ohne Werbenetzwerke. Radarbilder im Minutentakt und detaillierte Wind- und Luftdruckkurven. Schone deinen Akku durch effizientes Hintergrund-Polling.",
                category: "Lernen",
                versionString: "4.1.2",
                sizeBytes: 17_800_000,
                sourceName: "spanani.de",
                tint: Color(red: 0.20, green: 0.60, blue: 0.95),
                symbol: "cloud.sun.rain.fill",
                iconURL: nil,
                screenshotURLs: [],
                whatsNew: "Widget-Aktualisierung im Minutentakt bei drohendem Starkregen.",
                permissions: ["Ortungsdienste (Beim Verwenden)"],
                isFeatured: true,
                heroTagline: "Nur hier"
            ),
            StoreItem(
                id: "de.spanani.notizzettel",
                name: "Notizzettel",
                subtitle: "Schlichte Markdown-Notizen mit Git-Sync",
                developer: "Klartext Software",
                description: "Deine Gedanken in reinem Text, lokal gespeichert und auf Wunsch per Git synchronisiert. Schnelle Tastaturkürzel, Wiki-Verlinkungen und Tag-Organisation. Volle Kontrolle über deine persönlichen Notizen.",
                category: "Werkzeuge",
                versionString: "1.8.4",
                sizeBytes: 14_300_000,
                sourceName: "spanani.de",
                tint: Color(red: 0.85, green: 0.75, blue: 0.30),
                symbol: "note.text",
                iconURL: nil,
                screenshotURLs: [],
                whatsNew: "Unterstützung für mathematische Formeln und Mermaid-Diagramme.",
                permissions: ["Dateizugriff", "Lokaler Speicher"],
                isFeatured: false,
                heroTagline: ""
            ),
            StoreItem(
                id: "de.spanani.pomodoropur",
                name: "Pomodoro Pur",
                subtitle: "Fokussierte Arbeitsintervalle mit Naturklängen",
                developer: "Konzentrationswerk",
                description: "Arbeite produktiver mit klassischen 25-Minuten-Fokusphasen und sanften Pausen-Gongs. Begleitende Hintergrundgeräusche wie Waldregen oder Kaminfeuer fördern die Konzentration. Detaillierte Wochenstatistiken ohne Cloud-Zwang.",
                category: "Lernen",
                versionString: "2.0.0",
                sizeBytes: 36_200_000,
                sourceName: "spanani.de",
                tint: Color(red: 0.90, green: 0.35, blue: 0.40),
                symbol: "timer",
                iconURL: nil,
                screenshotURLs: [],
                whatsNew: "Neues Soundset 'Nordischer Wald' und anpassbare Pausenlängen.",
                permissions: ["Mitteilungen", "Hintergrund-Audio"],
                isFeatured: false,
                heroTagline: ""
            ),
            StoreItem(
                id: "de.spanani.sternenkarte",
                name: "Sternenkarte",
                subtitle: "Interaktives Planetarium für den Nachthimmel",
                developer: "Kosmos Gesellschaft",
                description: "Richte dein Gerät in den Nachthimmel und entdecke Sterne, Planeten und die Internationale Raumstation. Berechnet Satellitenüberflüge und Mondphasen offline im Taschenformat. Ideal für Sternfreunde und Nachtwanderungen.",
                category: "Lernen",
                versionString: "3.5.0",
                sizeBytes: 68_400_000,
                sourceName: "spanani.de",
                tint: Color(red: 0.45, green: 0.35, blue: 0.85),
                symbol: "sparkles",
                iconURL: nil,
                screenshotURLs: [],
                whatsNew: "Kometen-Katalog aktualisiert und AR-Positionsgenauigkeit verfeinert.",
                permissions: ["Kamera", "Kompass & Sensoren"],
                isFeatured: false,
                heroTagline: ""
            )
        ]

        let installed: [InstalledItem] = [
            InstalledItem(
                id: "de.spanani.fmhy",
                name: "FMHY",
                versionString: "1.5.1",
                tint: Color(red: 0.60, green: 0.33, blue: 0.91),
                symbol: "link.badge.plus",
                iconURL: nil,
                expiresAt: Date().addingTimeInterval(1 * 86400 + 3 * 3600),
                isActive: true,
                hasUpdate: true,
                latestVersion: "1.6.0"
            ),
            InstalledItem(
                id: "de.spanani.kippe",
                name: "Kippe",
                versionString: "1.0.4",
                tint: Color(red: 0.95, green: 0.45, blue: 0.25),
                symbol: "circle.grid.cross.fill",
                iconURL: nil,
                expiresAt: Date().addingTimeInterval(5 * 86400 + 14 * 3600),
                isActive: true,
                hasUpdate: false,
                latestVersion: nil
            )
        ]

        let sources: [SourceItem] = [
            SourceItem(
                id: "source-spanani",
                name: "spanani.de",
                url: "https://apps.spanani.de/source.json",
                appCount: 12,
                tint: .brand
            ),
            SourceItem(
                id: "source-community",
                name: "Community-Quelle",
                url: "https://community.spanani.de/apps.json",
                appCount: 8,
                tint: .accent
            )
        ]

        let account = AccountInfo(
            appleID: "dein.name@icloud.com",
            isPaired: true,
            vpnOn: true
        )

        return StoreModel(
            apps: apps,
            installed: installed,
            sources: sources,
            account: account,
            activeLimit: 3,
            actions: nil
        )
    }
}
