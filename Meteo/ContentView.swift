import SwiftUI

// 🔑 Clé API OpenWeather
func getAPIKey() -> String {
    if let path = Bundle.main.path(forResource: "Keys", ofType: "plist"),
       let dict = NSDictionary(contentsOfFile: path),
       let key = dict["OpenWeatherAPIKey"] as? String {
        return key
    }
    fatalError("❌ Clé API manquante ou mal nommée dans Keys.plist")
}

let apiKey = getAPIKey()

struct ContentView: View {
    @State private var city: String = ""
    @State private var weatherDescription: String = ""
    @State private var temperature: String = ""
    @State private var errorMessage: String = ""

    var body: some View {
        ZStack {
            // 🔹 Image de fond
            Image("FondColline")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            // 🔹 Le contenu "flottant" au-dessus
            VStack(spacing: 20) {
                Text("🌤️ Météo")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                TextField("Entrez une ville", text: $city)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)
                    .padding(.horizontal)

                Button("Rechercher") {
                    fetchWeather(for: city)
                }
                .font(.headline)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                .padding(.horizontal)

                if !weatherDescription.isEmpty {
                    Text(weatherDescription)
                        .font(.title2)

                    Text("\(temperature)°C")
                        .font(.largeTitle)
                        .bold()
                }

                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                Spacer()
            }
            .padding()
            .background(.ultraThinMaterial) // effet flou / verre dépoli
            .cornerRadius(25)
            .padding()
        }
    }
    
    func fetchWeather(for city: String) {
        let cityEncoded = city.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? city
        let urlString = "https://api.openweathermap.org/data/2.5/weather?q=\(cityEncoded)&appid=\(apiKey)&units=metric&lang=fr"

        guard let url = URL(string: urlString) else {
            DispatchQueue.main.async {
                self.errorMessage = "URL invalide"
            }
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = "Erreur réseau : \(error.localizedDescription)"
                }
                return
            }

            guard let data = data else {
                DispatchQueue.main.async {
                    self.errorMessage = "Pas de données reçues"
                }
                return
            }

            do {
                // Affiche la réponse JSON dans la console
                if let json = try? JSONSerialization.jsonObject(with: data, options: []),
                   let jsonData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted),
                   let jsonString = String(data: jsonData, encoding: .utf8) {
                    print("Réponse JSON brute :\n\(jsonString)")
                }

                let decoded = try JSONDecoder().decode(WeatherResponse.self, from: data)
                DispatchQueue.main.async {
                    self.weatherDescription = decoded.weather.first?.description.capitalized ?? "Pas de description"
                    self.temperature = String(Int(decoded.main.temp))
                    self.errorMessage = ""
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Ville non trouvée ou problème de décodage"
                }
            }
        }.resume()
    }
}

// Structures pour décoder la réponse JSON de l'API
struct WeatherResponse: Codable {
    let weather: [Weather]
    let main: Main
}

struct Weather: Codable {
    let description: String
}

struct Main: Codable {
    let temp: Double
}

// A SwiftUI preview.
#Preview {
    ContentView()
}
