const fs = require('fs');

let file = fs.readFileSync('mobile_app/lib/widgets/seance_groupe_dialog.dart', 'utf8');

// Normalize line endings to \n temporarily for reliable regex replacement
const hasCRLF = file.includes('\r\n');
let normalized = file.replace(/\r\n/g, '\n');

const target1 = `                                    if (isPresent)
                                      FilterChip(
                                        label: Text(
                                          isPaye ? 'Payé' : 'Non payé',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: isPaye ? Colors.white : Colors.grey[700],
                                          ),
                                        ),
                                        selected: isPaye,
                                        selectedColor: const Color(0xFF10B981),
                                        onSelected: (val) {
                                          setState(() {
                                            _payeMap[el.idEleve] = val;
                                          });
                                        },
                                      ),`;

const repl1 = `                                    if (isPresent)
                                      _estSeanceFuture
                                          ? Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                              decoration: BoxDecoration(
                                                color: Colors.blueGrey.withValues(alpha: 0.15),
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(color: Colors.blueGrey.withValues(alpha: 0.3)),
                                              ),
                                              child: const Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.lock_clock_rounded, size: 14, color: Colors.blueGrey),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    'À venir',
                                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                                                  ),
                                                ],
                                              ),
                                            )
                                          : FilterChip(
                                              label: Text(
                                                isPaye ? 'Payé' : 'Non payé',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: isPaye ? Colors.white : Colors.grey[700],
                                                ),
                                              ),
                                              selected: isPaye,
                                              selectedColor: const Color(0xFF10B981),
                                              onSelected: (val) {
                                                setState(() {
                                                  _payeMap[el.idEleve] = val;
                                                });
                                              },
                                            ),`;

const target2 = `                    label: const Text(
                      'Valider la séance',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),`;

const repl2 = `                    label: Text(
                      _estSeanceFuture ? 'Planifier la séance' : 'Valider la séance',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),`;

if (!normalized.includes(target1)) {
  console.error('Target 1 not found!');
  process.exit(1);
}

normalized = normalized.replace(target1, repl1);
normalized = normalized.replace(target2, repl2);

if (hasCRLF) {
  normalized = normalized.replace(/\n/g, '\r\n');
}

fs.writeFileSync('mobile_app/lib/widgets/seance_groupe_dialog.dart', normalized, 'utf8');
console.log('Successfully updated seance_groupe_dialog.dart');
