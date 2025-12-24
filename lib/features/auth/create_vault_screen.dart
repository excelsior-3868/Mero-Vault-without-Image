import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/vault_provider.dart';
import '../home/dashboard_screen.dart';

class CreateVaultScreen extends StatefulWidget {
  const CreateVaultScreen({super.key});

  @override
  State<CreateVaultScreen> createState() => _CreateVaultScreenState();
}

class _CreateVaultScreenState extends State<CreateVaultScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;

  Future<void> _createVault() async {
    if (_passwordController.text != _confirmController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }
    if (_passwordController.text.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 8 characters')),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      final vaultProvider = Provider.of<VaultProvider>(context, listen: false);
      await vaultProvider.createNewVault(_passwordController.text);
      
      if (mounted) {
         // Navigate to Dashboard
         Navigator.of(context).pushReplacement(
           MaterialPageRoute(builder: (_) => const DashboardScreen()),
         );
      }
    } catch (e) {
       if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating vault: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Setup New Vault')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Text(
              'Create a Master Password. This password is the ONLY way to access your data. We cannot recover it for you.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Master Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 32),
            if (_isLoading)
              const CircularProgressIndicator()
            else
              ElevatedButton(
                onPressed: _createVault,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD32F2F),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('Create Vault'),
              ),
          ],
        ),
      ),
    );
  }
}
