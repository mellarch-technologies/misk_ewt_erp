import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/initiative_provider.dart';

class InitiativesListScreen extends StatelessWidget {
  const InitiativesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<InitiativeProvider>(context);
    return Scaffold(
      appBar: AppBar(title: Text('Initiatives')),
      body: RefreshIndicator(
        onRefresh: provider.fetchInitiatives,
        child: provider.isBusy
            ? Center(child: CircularProgressIndicator())
            : provider.initiatives.isEmpty
                ? Center(child: Text('No initiatives found.'))
                : ListView.builder(
                    itemCount: provider.initiatives.length,
                    itemBuilder: (context, i) {
                      final initiative = provider.initiatives[i];
                      return ListTile(
                        title: Text(initiative.title),
                        subtitle: Text(initiative.description ?? ''),
                        onTap: () {
                          // TODO: Navigate to detail screen
                        },
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/initiatives/form');
        },
        child: Icon(Icons.add),
      ),
    );
  }
}

