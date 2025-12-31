import { StatusBar } from 'expo-status-bar';
import { StyleSheet, Text, View, TouchableOpacity, Linking, Image } from 'react-native';

// Point to the deployed web app
const WEB_APP_URL = 'http://89.117.60.144:3003';

export default function App() {
  const openWebApp = () => {
    Linking.openURL(WEB_APP_URL);
  };

  return (
    <View style={styles.container}>
      <StatusBar style="light" />
      
      {/* Logo */}
      <View style={styles.logoContainer}>
        <Text style={styles.logoEmoji}>📚</Text>
      </View>
      
      <Text style={styles.title}>UPSC PrepX AI</Text>
      <Text style={styles.subtitle}>Your AI-Powered UPSC Preparation Partner</Text>
      
      {/* Features list */}
      <View style={styles.featuresContainer}>
        <Text style={styles.featureItem}>✨ AI-Generated Notes</Text>
        <Text style={styles.featureItem}>📝 Practice MCQs & PYQs</Text>
        <Text style={styles.featureItem}>📰 Daily Current Affairs</Text>
        <Text style={styles.featureItem}>🎥 Video Content</Text>
        <Text style={styles.featureItem}>📊 Progress Tracking</Text>
      </View>
      
      <TouchableOpacity style={styles.button} onPress={openWebApp}>
        <Text style={styles.buttonText}>Open UPSC PrepX</Text>
      </TouchableOpacity>
      
      <Text style={styles.versionText}>Version 1.0.0</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#1a1a2e',
    alignItems: 'center',
    justifyContent: 'center',
    padding: 20,
  },
  logoContainer: {
    width: 100,
    height: 100,
    borderRadius: 50,
    backgroundColor: '#00f3ff20',
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: 20,
  },
  logoEmoji: {
    fontSize: 50,
  },
  title: {
    fontSize: 28,
    fontWeight: 'bold',
    color: '#fff',
    marginBottom: 8,
  },
  subtitle: {
    fontSize: 14,
    color: '#a0a0a0',
    textAlign: 'center',
    marginBottom: 30,
  },
  featuresContainer: {
    marginBottom: 30,
  },
  featureItem: {
    fontSize: 16,
    color: '#00f3ff',
    marginBottom: 10,
  },
  button: {
    backgroundColor: '#00f3ff',
    paddingHorizontal: 40,
    paddingVertical: 15,
    borderRadius: 25,
    marginBottom: 20,
  },
  buttonText: {
    color: '#1a1a2e',
    fontSize: 18,
    fontWeight: 'bold',
  },
  versionText: {
    fontSize: 12,
    color: '#666',
    marginTop: 20,
  },
});
