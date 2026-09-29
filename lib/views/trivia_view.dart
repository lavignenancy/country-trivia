import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../viewmodels/trivia_viewmodel.dart';

class TriviaView extends StatelessWidget {
  const TriviaView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Country Trivia'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Consumer<TriviaViewModel>(
                builder: (context, vm, _) => Text(
                  'Score: ${vm.score}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Consumer<TriviaViewModel>(
        builder: (context, vm, _) {
          if (vm.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (vm.errorMessage != null) {
            return _buildError(context, vm);
          }

          if (vm.gameComplete) {
            return _buildGameComplete(context, vm);
          }

          return _buildGameBody(context, vm);
        },
      ),
    );
  }

  Widget _buildError(BuildContext context, TriviaViewModel vm) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              vm.errorMessage!,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => vm.loadGame(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameComplete(BuildContext context, TriviaViewModel vm) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.emoji_events, size: 80, color: Colors.amber),
            const SizedBox(height: 24),
            const Text(
              'Congratulations!',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Final Score: ${vm.score}',
              style: const TextStyle(fontSize: 22),
            ),
            const SizedBox(height: 8),
            Text(
              'You solved all ${vm.totalCountries} countries!',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => vm.resetGame(),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Play Again', style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameBody(BuildContext context, TriviaViewModel vm) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Progress indicator
          _buildProgress(vm),
          const SizedBox(height: 12),

          // Flag display
          _buildFlag(vm),
          const SizedBox(height: 20),

          // Question text
          const Text(
            'Which country does this flag belong to?',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),

          // Attempts indicator
          _buildAttemptDots(vm),
          const SizedBox(height: 20),

          // Answer options
          ...vm.options.map((country) => _buildAnswerButton(vm, country.name)),

          const SizedBox(height: 12),

          // Feedback message
          if (vm.feedbackMessage.isNotEmpty) _buildFeedback(vm),

          const Spacer(),

          // Next button
          if (vm.hasAnswered)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => vm.nextQuestion(),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Next Question', style: TextStyle(fontSize: 18)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProgress(TriviaViewModel vm) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '${vm.solvedCount} / ${vm.totalCountries} solved',
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildFlag(TriviaViewModel vm) {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: vm.correctCountry != null
            ? CachedNetworkImage(
                imageUrl: vm.correctCountry!.flagUrl,
                fit: BoxFit.contain,
                placeholder: (context, url) =>
                    const Center(child: CircularProgressIndicator()),
                errorWidget: (context, url, error) => const Center(
                  child: Icon(Icons.image_not_supported,
                      size: 50, color: Colors.grey),
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildAttemptDots(TriviaViewModel vm) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Icon(
            Icons.circle,
            size: 16,
            color: index < vm.attempts ? Colors.red : Colors.grey.shade300,
          ),
        );
      }),
    );
  }

  Widget _buildAnswerButton(TriviaViewModel vm, String countryName) {
    final isSelected = vm.selectedAnswer == countryName;
    final isCorrect = countryName == vm.correctCountry?.name;
    final showCorrect = vm.hasAnswered && isCorrect;
    final showWrong = vm.hasAnswered && isSelected && !isCorrect;

    Color buttonColor = Colors.grey.shade100;
    Color borderColor = Colors.grey.shade300;

    if (showCorrect) {
      buttonColor = Colors.green.shade100;
      borderColor = Colors.green;
    } else if (showWrong) {
      buttonColor = Colors.red.shade100;
      borderColor = Colors.red;
    } else if (isSelected) {
      buttonColor = Colors.orange.shade100;
      borderColor = Colors.orange;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: vm.hasAnswered ? null : () => vm.selectAnswer(countryName),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            backgroundColor: buttonColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: borderColor, width: 2),
            ),
            elevation: 0,
          ),
          child: Text(
            countryName,
            style: const TextStyle(fontSize: 16, color: Colors.black87),
          ),
        ),
      ),
    );
  }

  Widget _buildFeedback(TriviaViewModel vm) {
    Color feedbackColor;
    if (vm.feedbackMessage.startsWith('Correct')) {
      feedbackColor = Colors.green;
    } else if (vm.feedbackMessage.startsWith('Out of attempts')) {
      feedbackColor = Colors.red;
    } else {
      feedbackColor = Colors.orange;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: feedbackColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: feedbackColor),
      ),
      child: Text(
        vm.feedbackMessage,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: feedbackColor,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
