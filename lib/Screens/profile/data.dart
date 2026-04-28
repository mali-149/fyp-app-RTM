class MechanicData {
  // 🧠 SMART CLEAN INPUT (case + spacing + symbols fix)
  static String normalize(String text) {
    return text
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^\w\s]'), '') // remove symbols
        .replaceAll(RegExp(r'\s+'), ' '); // remove extra spaces
  }

  // 💬 CHAT / GREETINGS
  static Map<String, String> chatReplies = {
    "hi": "Hello 👋 Welcome to Ride to Mechanic!",
    "hello": "Hi there 😊 How can I help you today?",
    "how are you": "I'm fine 👍 Ready to help with your vehicle issues!",
    "fine": "Great 😊 Tell me your vehicle problem!",
    "thanks": "You're welcome 😊",
    "thank you": "Happy to help 🚗",
    "bye": "Goodbye 👋 Drive safely!",
    "who are you": "I'm Ride to Mechanic AI 🤖, your vehicle assistant!",

    "help": "Tell me your issue like:\n- bike not starting\n- car not starting\n- engine overheating",

    "how you work":
    "🚗 Ride to Mechanic helps you diagnose vehicle issues.\n\n"
        "👉 Type your problem\n"
        "👉 Get cause + solution + parts\n"
        "👉 Then repair or visit mechanic",

    "how does this app work":
    "🔧 This app analyzes vehicle problems and gives:\n"
        "✔ Problem details\n"
        "✔ Cause\n"
        "✔ Solution\n"
        "✔ Parts with prices"
  };

  // 🚗 VEHICLE ISSUES DATABASE
  static Map<String, Map<String, dynamic>> issues = {
    "bike not starting": {
      "problem": "Bike is not starting",
      "cause": "Battery weak, spark plug fault, or fuel issue",
      "solution": "Check battery, clean/replace spark plug, check fuel level",
      "parts": [
        {"name": "Battery", "price": "3000 - 8000 PKR"},
        {"name": "Spark Plug", "price": "300 - 800 PKR"},
        {"name": "Fuel Filter", "price": "500 - 1500 PKR"}
      ]
    },

    "car not starting": {
      "problem": "Car engine not starting",
      "cause": "Dead battery, starter motor issue, or fuel pump failure",
      "solution": "Jump start battery, check starter motor, check fuel system",
      "parts": [
        {"name": "Car Battery", "price": "15000 - 40000 PKR"},
        {"name": "Starter Motor", "price": "12000 - 30000 PKR"},
        {"name": "Fuel Pump", "price": "8000 - 25000 PKR"}
      ]
    },

    "engine overheating": {
      "problem": "Engine overheating",
      "cause": "Low coolant, radiator blockage, or fan issue",
      "solution": "Refill coolant, clean radiator, check cooling fan",
      "parts": [
        {"name": "Coolant", "price": "1000 - 3000 PKR"},
        {"name": "Radiator", "price": "8000 - 20000 PKR"},
        {"name": "Radiator Fan", "price": "5000 - 12000 PKR"}
      ]
    },

    "brake noise": {
      "problem": "Brake making noise",
      "cause": "Worn brake pads or dirty disc",
      "solution": "Replace brake pads and clean brake disc",
      "parts": [
        {"name": "Brake Pads", "price": "2000 - 6000 PKR"},
        {"name": "Brake Disc", "price": "5000 - 15000 PKR"}
      ]
    },

    "bike tyre puncture": {
      "problem": "Bike tyre puncture",
      "cause": "Sharp object or worn tyre",
      "solution": "Repair puncture or replace tyre",
      "parts": [
        {"name": "Tyre Tube", "price": "500 - 1500 PKR"},
        {"name": "Tyre", "price": "2000 - 6000 PKR"}
      ]
    },

    "oil leakage": {
      "problem": "Engine oil leakage",
      "cause": "Gasket damage or loose filter",
      "solution": "Replace gasket and tighten oil filter",
      "parts": [
        {"name": "Engine Gasket", "price": "1000 - 4000 PKR"},
        {"name": "Oil Filter", "price": "500 - 2000 PKR"}
      ]
    },

    "ac not working": {
      "problem": "Car AC not working",
      "cause": "Low gas or compressor issue",
      "solution": "Refill gas and check compressor",
      "parts": [
        {"name": "AC Gas", "price": "2000 - 6000 PKR"},
        {"name": "AC Compressor", "price": "15000 - 50000 PKR"}
      ]
    }
  };

  // ❓ SMART UNKNOWN RESPONSE
  static String unknownResponse =
      "⚠️ Sorry, I couldn’t understand your issue.\n\n"
      "👉 Try typing like:\n"
      "- bike not starting\n"
      "- car not starting\n"
      "- engine overheating\n"
      "- brake noise\n\n"
      "📍 Or visit your nearest mechanic for proper diagnosis.";
}