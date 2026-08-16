import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/emergency_contact_entity.dart';
import '../../domain/repositories/contacts_repository.dart';
import '../datasources/contacts_remote_datasource.dart';

class ContactsRepositoryImpl implements ContactsRepository {
  ContactsRepositoryImpl(this.remoteDataSource);

  final ContactsRemoteDataSource remoteDataSource;

  @override
  Future<Either<Failure, List<EmergencyContactEntity>>> getContacts() async {
    try {
      final contacts = await remoteDataSource.getContacts();
      return Right(contacts);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on PostgrestException catch (e) {
      return Left(ServerFailure('Erro ao buscar contatos: ${e.message}'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, EmergencyContactEntity>> addContact({
    required String name,
    required String phone,
    String? relationship,
  }) async {
    try {
      final contact = await remoteDataSource.addContact(
        name: name,
        phone: phone,
        relationship: relationship,
      );
      return Right(contact);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        return const Left(
          ValidationFailure('Este telefone já está cadastrado como contato.'),
        );
      }
      return Left(ServerFailure('Erro ao salvar contato: ${e.message}'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteContact(String contactId) async {
    try {
      await remoteDataSource.deleteContact(contactId);
      return const Right(null);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on PostgrestException catch (e) {
      return Left(ServerFailure('Erro ao remover contato: ${e.message}'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
