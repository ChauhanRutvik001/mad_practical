import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/task.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get the current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // ----- Task Management Methods -----
  
  // Save a task to Firestore
  Future<String?> saveTask(Task task) async {
    try {
      // Make sure user is logged in
      if (currentUserId == null) {
        throw Exception('User not logged in');
      }

      // Reference to the user's tasks collection
      final userTasksRef = _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('tasks');

      // Add the task document
      final docRef = await userTasksRef.add(task.toMap());

      print('Task saved with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('Error saving task: $e');
      return null;
    }
  }

  // Get all tasks for the current user
  Future<List<Task>> getUserTasks() async {
    try {
      // Make sure user is logged in
      if (currentUserId == null) {
        return [];
      }

      // Get all tasks for the user
      final snapshot = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('tasks')
          .orderBy('createdAt', descending: true)
          .get();

      // Convert snapshots to Task objects
      return snapshot.docs.map((doc) {
        return Task.fromMap(doc.data(), doc.id);
      }).toList();
    } catch (e) {
      print('Error getting tasks: $e');
      return [];
    }
  }

  // Update a task
  Future<bool> updateTask(Task task) async {
    try {
      // Make sure user is logged in
      if (currentUserId == null) {
        return false;
      }

      // Update the task document
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('tasks')
          .doc(task.id)
          .update(task.toMap());

      return true;
    } catch (e) {
      print('Error updating task: $e');
      return false;
    }
  }

  // Delete a task
  Future<bool> deleteTask(String taskId) async {
    try {
      // Make sure user is logged in
      if (currentUserId == null) {
        return false;
      }

      // Delete the task document
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('tasks')
          .doc(taskId)
          .delete();

      return true;
    } catch (e) {
      print('Error deleting task: $e');
      return false;
    }
  }
}
